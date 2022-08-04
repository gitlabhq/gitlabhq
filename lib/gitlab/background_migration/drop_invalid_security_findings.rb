# frozen_string_literal: true
module Gitlab
  module BackgroundMigration
    # Drop rows from security_findings where the uuid is NULL
    class DropInvalidSecurityFindings
      # rubocop:disable Style/Documentation
      class SecurityFinding < ActiveRecord::Base
        include ::EachBatch
        self.table_name = 'security_findings'
        scope :no_uuid, -> { where(uuid: nil) }
      end
      # rubocop:enable Style/Documentation

      PAUSE_SECONDS = 0.1

      def perform(start_id, end_id, sub_batch_size)
        ranged_query = SecurityFinding
          .where(id: start_id..end_id)
          .no_uuid

        ranged_query.each_batch(of: sub_batch_size) do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(id), max(id)'))

          # The query need to be reconstructed because .each_batch modifies the default scope
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/330510
          SecurityFinding.unscoped
            .where(id: first..last)
            .no_uuid
            .delete_all

          sleep PAUSE_SECONDS
        end

        mark_job_as_succeeded(start_id, end_id, sub_batch_size)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
