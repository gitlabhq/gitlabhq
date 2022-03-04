# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Migrates personal namespace project `maintainer` memberships (for the associated user only) to OWNER
    # Does not create any missing records, simply migrates existing ones
    class MigratePersonalNamespaceProjectMaintainerToOwner
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms)
        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          batch_metrics.time_operation(:update_all) do
            sub_batch.update_all('access_level = 50')
          end

          pause_ms = 0 if pause_ms < 0
          sleep(pause_ms * 0.001)
        end
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        # members of projects within their own personal namespace

        # rubocop: disable CodeReuse/ActiveRecord
        define_batchable_model(:members, connection: ApplicationRecord.connection)
          .where(source_key_column => start_id..stop_id)
          .joins("INNER JOIN projects ON members.source_id = projects.id")
          .joins("INNER JOIN namespaces ON projects.namespace_id = namespaces.id")
          .where(type: 'ProjectMember')
          .where("namespaces.type = 'User'")
          .where('members.access_level < 50')
          .where('namespaces.owner_id = members.user_id')
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
