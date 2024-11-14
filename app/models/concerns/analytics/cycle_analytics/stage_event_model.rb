# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module StageEventModel
      extend ActiveSupport::Concern

      included do
        include FromUnion
        include Awardable

        scope :by_stage_event_hash_id, ->(id) { where(stage_event_hash_id: id) }
        scope :by_project_id, ->(id) { where(project_id: id) }
        scope :by_group_id, ->(id) { where(group_id: id) }
        scope :end_event_timestamp_after, ->(date) { where(arel_table[:end_event_timestamp].gteq(date)) }
        scope :end_event_timestamp_before, ->(date) { where(arel_table[:end_event_timestamp].lteq(date)) }
        scope :start_event_timestamp_after, ->(date) { where(arel_table[:start_event_timestamp].gteq(date)) }
        scope :start_event_timestamp_before, ->(date) { where(arel_table[:start_event_timestamp].lteq(date)) }
        scope :authored, ->(user) { where(author_id: user) }
        scope :with_milestone_id, ->(milestone_id) { where(milestone_id: milestone_id) }
        scope :without_milestone_id,
          ->(milestone_id) { where('milestone_id <> ? or milestone_id IS NULL', milestone_id) }
        scope :end_event_is_not_happened_yet, -> { where(end_event_timestamp: nil) }
        scope :for_consistency_check_worker, ->(direction) do
          keyset_order(
            :end_event_timestamp => {
              order_expression: arel_order(arel_table[:end_event_timestamp], direction),
              nullable: direction == :asc ? :nulls_last : :nulls_first
            },
            issuable_id_column => {
              order_expression: arel_order(arel_table[issuable_id_column], direction),
              nullable: :not_nullable
            }
          )
        end
        scope :order_by_end_event, ->(direction) do
          # ORDER BY end_event_timestamp, merge_request_id/issue_id, start_event_timestamp
          # start_event_timestamp must be included in the ORDER BY clause for the duration
          # calculation to work: SELECT end_event_timestamp - start_event_timestamp
          keyset_order(
            :end_event_timestamp => {
              order_expression: arel_order(arel_table[:end_event_timestamp], direction),
              nullable: direction == :asc ? :nulls_last : :nulls_first
            },
            issuable_id_column => { order_expression: arel_order(arel_table[issuable_id_column], direction) },
            :start_event_timestamp => { order_expression: arel_order(arel_table[:start_event_timestamp], direction) }
          )
        end
        scope :order_by_end_event_with_db_duration, ->(direction) do
          # ORDER BY end_event_timestamp, merge_request_id/issue_id, start_event_timestamp
          # start_event_timestamp must be included in the ORDER BY clause for the duration
          # calculation to work: SELECT end_event_timestamp - start_event_timestamp
          keyset_order(
            :end_event_timestamp => {
              order_expression: arel_order(arel_table[:end_event_timestamp], direction),
              nullable: direction == :asc ? :nulls_last : :nulls_first
            },
            issuable_id_column => { order_expression: arel_order(arel_table[issuable_id_column], direction) },
            :start_event_timestamp => { order_expression: arel_order(arel_table[:start_event_timestamp], direction) },
            :duration_in_milliseconds => {
              order_expression: arel_order(arel_table[:duration_in_milliseconds], direction),
              nullable: direction == :asc ? :nulls_last : :nulls_first, sql_type: 'bigint'
            }
          )
        end
        scope :order_by_db_duration, ->(direction) do
          # start_event_timestamp and end_event_timestamp do not really influence the order,
          # but are included so that they are part of the returned result, for example when
          # using Gitlab::Analytics::CycleAnalytics::Aggregated::RecordsFetcher
          keyset_order(
            :duration_in_milliseconds => {
              order_expression: arel_order(arel_table[:duration_in_milliseconds], direction),
              nullable: direction == :asc ? :nulls_last : :nulls_first, sql_type: 'bigint'
            },
            issuable_id_column => { order_expression: arel_order(arel_table[issuable_id_column], direction) },
            :end_event_timestamp => { order_expression: arel_order(arel_table[:end_event_timestamp], direction) },
            :start_event_timestamp => { order_expression: arel_order(arel_table[:start_event_timestamp], direction) }
          )
        end

        scope :not_authored, ->(user_id) { where(author_id: nil).or(where.not(author_id: user_id)) }
        scope :not_assigned_to, ->(user) do
          condition = assignees_model
            .where(user_id: user)
            .where(arel_table[issuable_id_column].eq(assignees_model.arel_table[issuable_id_column]))

          where(condition.arel.exists.not)
        end
      end

      def issuable_id
        attributes[self.class.issuable_id_column.to_s]
      end

      def total_time
        duration_in_milliseconds&.fdiv(1000)
      end

      class_methods do
        def upsert_data(data)
          upsert_values = data.map { |row| row.values_at(*column_list) }

          value_list = Arel::Nodes::ValuesList.new(upsert_values).to_sql

          query = <<~SQL
          INSERT INTO #{quoted_table_name}
          (
            #{insert_column_list.join(",\n")}
          )
          #{value_list}
          ON CONFLICT(stage_event_hash_id, #{issuable_id_column})
          DO UPDATE SET
            #{column_updates.join(",\n")}
          SQL

          result = connection.execute(query)
          result.cmd_tuples
        end

        def keyset_order(column_definition_options)
          built_definitions = column_definition_options.map do |attribute_name, column_options|
            ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(attribute_name: attribute_name, **column_options)
          end

          order(Gitlab::Pagination::Keyset::Order.build(built_definitions))
        end

        def arel_order(arel_node, direction)
          direction.to_sym == :desc ? arel_node.desc : arel_node.asc
        end

        def select_columns
          [
            issuable_model.arel_table[:id],
            issuable_model.arel_table[project_column].as('project_id'),
            issuable_model.arel_table[:milestone_id],
            issuable_model.arel_table[:author_id],
            issuable_model.arel_table[:state_id],
            Project.arel_table[:parent_id].as('group_id')
          ]
        end

        def column_list
          [
            :stage_event_hash_id,
            :issuable_id,
            :group_id,
            :project_id,
            :milestone_id,
            :author_id,
            :state_id,
            :start_event_timestamp,
            :end_event_timestamp,
            :duration_in_milliseconds
          ]
        end

        def insert_column_list
          [
            :stage_event_hash_id,
            connection.quote_column_name(issuable_id_column),
            :group_id,
            :project_id,
            :milestone_id,
            :author_id,
            :state_id,
            :start_event_timestamp,
            :end_event_timestamp,
            :duration_in_milliseconds
          ]
        end

        def column_updates
          insert_column_list.map do |column|
            "#{column} = excluded.#{column}"
          end
        end
      end
    end
  end
end
