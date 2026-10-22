# frozen_string_literal: true

module Organizations
  module Transfer
    module Concerns
      module OrganizationUpdater
        extend ActiveSupport::Concern

        ORGANIZATION_ID_UPDATE_BATCH_SIZE = 1000

        # Update organization_id for records matching the scope specified in the block
        # @param model_class [Class] The ActiveRecord model class
        # @param organization_key [Symbol] The column name for organization_id (default: :organization_id)
        # @param block Scope to filter records
        #
        # @example Update with hash where clause
        #   update_organization_id_for(PersonalAccessToken) { |relation| relation.where(user_id: [1, 2, 3]) }
        #
        # @example Update with model scopes
        #   update_organization_id_for(PersonalAccessToken) { |relation| relation.where(user_id: user_ids).active }
        #
        # @example Update without a block
        #   update_organization_id_for(PersonalAccessToken)
        #
        # @example Update with a custom organization key
        #   update_organization_id_for(SnippetRepository, organization_key: :snippet_organization_id)
        #
        # rubocop:disable CodeReuse/ActiveRecord -- Not every model supports `in_organization` scope yet.
        def update_organization_id_for(model_class, organization_key: :organization_id, &block)
          raise ArgumentError, 'old and new organization must differ' if old_organization.id == new_organization.id

          relation = model_class.where(organization_key => old_organization.id)
          relation = yield(relation) if block

          capture_upserts = iam_replicable?(model_class)
          primary_key = model_class.primary_key
          partition_key = model_class.try(:partitioning_strategy)&.partitioning_key
          previous_ids = nil

          # No ORDER BY: with one, the planner walks the primary key instead of the filter's index.
          # Each pass moves its rows out of old_organization, so the next pluck finds new ones.
          loop do
            rows = relation.limit(ORGANIZATION_ID_UPDATE_BATCH_SIZE).pluck(*[primary_key, partition_key].compact)
            # Sorted so the repeat check below does not depend on the unordered pluck's row order.
            ids = (partition_key ? rows.map(&:first) : rows).sort
            break if ids.empty? || ids == previous_ids

            conditions = { primary_key => ids, organization_key => old_organization.id }
            # Filtering on the partition key lets PostgreSQL prune to the partitions holding these rows.
            conditions[partition_key] = rows.map(&:last).uniq if partition_key

            break if model_class.where(conditions).update_all(organization_key => new_organization.id) == 0

            model_class.record_iam_outbox_upserts(model_class.where(primary_key => ids)) if capture_upserts
            previous_ids = ids
          end
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def iam_replicable?(model_class)
          model_class.respond_to?(:iam_outbox_entity_type) && model_class.iam_outbox_entity_type.present?
        end
      end
    end
  end
end
