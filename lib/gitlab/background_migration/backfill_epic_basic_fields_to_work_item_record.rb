# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEpicBasicFieldsToWorkItemRecord < BatchedMigrationJob
      feature_category :team_planning
      operation_name :backfill_epics_base_fields_data_into_work_items

      job_arguments :group_id
      scope_to ->(relation) { group_id.present? ? relation.where(group_id: group_id) : relation }

      WORK_ITEM_TYPE_EPIC = 7 # see WorkItems::Type::BASE_TYPES[:epic][:enum_value]
      DEFAULT_EPIC_COLOR = '#1068bf' # see Epic::DEFAULT_COLOR
      NON_MATCHING_BASIC_FIELDS = { tmp_epic_id: :id, namespace_id: :group_id, relative_position: :id }.freeze
      MATCHING_BASIC_FIELDS = %i[
        author_id iid state_id title title_html description description_html cached_markdown_version lock_version
        last_edited_at last_edited_by_id created_at updated_at closed_at closed_by_id confidential
        external_key imported_from
      ].freeze

      class Epics < ApplicationRecord
        self.table_name = 'epics'
        self.inheritance_column = :_type_disabled
      end

      class Issues < ApplicationRecord
        self.table_name = 'issues'
        self.inheritance_column = :_type_disabled
      end

      class Users < ApplicationRecord
        self.table_name = 'users'
        self.inheritance_column = :_type_disabled
      end

      class WorkItemColors < ApplicationRecord
        self.table_name = 'work_item_colors'
        self.inheritance_column = :_type_disabled
      end

      class WorkItemTypes < ApplicationRecord
        self.table_name = 'work_item_types'
        self.inheritance_column = :_type_disabled
      end

      def perform
        each_sub_batch do |sub_batch|
          # prevent an epic being updated while we sync its data to issues table. Wrap the locking into a transaction
          # so that locks are kept for the duration of transaction.
          sub_batch_with_lock = sub_batch.lock!('FOR UPDATE')
          # First update any epics with a not null issue_id and only afterwards follow-up with the epics
          # without an issue_id, otherwise we end up updating the same issues/epics twice, as first time we'd
          # fetch epics without an issue_id then set the issue_id and then we query the same batch for epics
          # with an issue_id we just did set.
          backfill_epics_with_synced_work_item(sub_batch_with_lock)
          backfill_epics_without_synced_work_item(sub_batch_with_lock)
          # force reload the batch as it now should have the issue_id set and we need it
          # to create work_item_colors records.
          backfill_epics_color(sub_batch_with_lock.all)
        end
      end

      private

      def backfill_epics_without_synced_work_item(sub_batch)
        Issues.transaction do
          cte = Gitlab::SQL::CTE.new(:batched_relation, sub_batch)
          without_sync_work_item = cte.apply_to(Epics.all).where(issue_id: nil)
          work_items = build_work_items(epic_work_item_type_id, without_sync_work_item)

          unless work_items.blank?
            id_pairs = Issues.upsert_all(
              work_items, unique_by: :tmp_epic_id, returning: [:id, :tmp_epic_id]
            )

            connection.execute(update_issue_id_on_epics_query(id_pairs)) unless id_pairs.empty?
          end
        end
      end

      def backfill_epics_with_synced_work_item(sub_batch)
        Issues.transaction do
          cte = Gitlab::SQL::CTE.new(:batched_relation, sub_batch)
          with_sync_work_item = cte.apply_to(Epics.all).where.not(issue_id: nil)
          work_items = build_work_items(epic_work_item_type_id, with_sync_work_item, epics_with_synced_work_item: true)

          Issues.upsert_all(work_items, unique_by: :id) unless work_items.blank?
        end
      end

      def backfill_epics_color(sub_batch)
        Issues.transaction do
          work_items_color = build_work_items_color(sub_batch)

          WorkItemColors.upsert_all(work_items_color, unique_by: :issue_id) unless work_items_color.blank?
        end
      end

      def epic_work_item_type_id
        @epic_work_item_type_id ||= WorkItemTypes.where(base_type: WORK_ITEM_TYPE_EPIC).first.id
      end

      def update_issue_id_on_epics_query(id_pairs)
        values = id_pairs.map { |pair| "(#{pair['id']}, #{pair['tmp_epic_id']})" }.join(', ')

        <<-SQL.squish
          UPDATE epics
          SET issue_id = id_pairs.issue_id
          FROM ( VALUES #{values} ) AS id_pairs(issue_id, epic_id)
          WHERE epics.id = epic_id
        SQL
      end

      def build_work_items(epic_work_item_type_id, epics_batch, epics_with_synced_work_item: false)
        updated_by_user_ids = Users.joins("INNER JOIN epics ON epics.updated_by_id = users.id")
                                .where(epics: { id: epics_batch })
                                .select("epics.id AS epic_id, users.id AS updated_by_id").to_a
                                .to_h { |record| [record.epic_id, record.updated_by_id] }

        epics_batch.flat_map do |epic|
          attributes = {}
          attributes[:work_item_type_id] = epic_work_item_type_id
          attributes[:id] = epic.issue_id if epics_with_synced_work_item

          # on epics table we are missing a FK to users table on updated_by_id,
          # so instead we'd use the value from users table, which would be NULL in case of mismatch.
          attributes[:updated_by_id] = updated_by_user_ids[epic.id]

          MATCHING_BASIC_FIELDS.each { |attr| attributes[attr] = epic[attr] }
          NON_MATCHING_BASIC_FIELDS.each_pair { |attr, epic_attr| attributes[attr] = epic[epic_attr] }

          attributes
        end
      end

      def build_work_items_color(epics_batch)
        work_items_colors_batch = WorkItemColors.where(issue_id: epics_batch.select(:issue_id)).to_a
        epics_batch.flat_map do |epic|
          work_item_color = work_items_colors_batch.find { |record| record.issue_id = epic.issue_id }

          next if skip_epic_color_sync?(epic, work_item_color)

          {
            issue_id: epic.issue_id,
            color: epic.color,
            namespace_id: epic.group_id,
            created_at: epic.created_at,
            updated_at: epic.updated_at
          }
        end.compact
      end

      # If epic color is default and there is no record for the work item color then do not sync, we do not have to
      # sync default color as that is assumed by default on the epic work item.
      # Also if the epic color is the same with the existing work item color, skip synching as well.
      def skip_epic_color_sync?(epic, work_item_color)
        (epic.color.to_s == DEFAULT_EPIC_COLOR && work_item_color.nil?) || epic.color == work_item_color&.color
      end

      # when we need to filter epics tobe back-filled by group_id we do not have a good index coverage on
      # (id, group_id) pair, so instead because we have (group_id, iid) pair covered by an unique index we can
      # use that to iterate in batches
      def batch_column
        group_id.present? ? :iid : :id
      end
    end
  end
end
