# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class ArchiveLegacyTraces
      def perform(start_id, stop_id)
        # This background migrations directly refer ::Ci::Build model which is defined in application code.
        # In general, migration code should be isolated as much as possible in order to be idempotent.
        # However, `archive!` logic is too complicated to be replicated. So we chose a way to refer ::Ci::Build directly
        # and we don't change the `archive!` logic until 11.1
        ::Ci::Build.finished.without_archived_trace
          .where(id: start_id..stop_id).find_each do |build|
            begin
              build.trace.archive!
            rescue => e
              Rails.logger.error "Failed to archive live trace. id: #{build.id} message: #{e.message}"
            end
          end
      end
    end
  end
end
