# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class CopyMergeRequestTargetProjectToMergeRequestMetrics
      extend ::Gitlab::Utils::Override

      def perform(start_id, stop_id)
        ActiveRecord::Base.connection.execute <<~SQL
          WITH merge_requests_batch AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
            SELECT id, target_project_id
            FROM merge_requests WHERE id BETWEEN #{Integer(start_id)} AND #{Integer(stop_id)}
          )
          UPDATE
            merge_request_metrics
          SET
            target_project_id = merge_requests_batch.target_project_id
          FROM merge_requests_batch
          WHERE merge_request_metrics.merge_request_id=merge_requests_batch.id
        SQL
      end
    end
  end
end
