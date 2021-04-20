# frozen_string_literal: true

module MergeRequests
  class MigrateExternalDiffsService < ::BaseService
    MAX_JOBS = 1000

    attr_reader :diff

    def self.enqueue!
      ids = MergeRequestDiff.ids_for_external_storage_migration(limit: MAX_JOBS)

      # rubocop:disable Scalability/BulkPerformWithContext
      # https://gitlab.com/gitlab-org/gitlab/issues/202100
      MigrateExternalDiffsWorker.bulk_perform_async(ids.map { |id| [id] })
      # rubocop:enable Scalability/BulkPerformWithContext
    end

    def initialize(merge_request_diff)
      @diff = merge_request_diff
    end

    def execute
      diff.migrate_files_to_external_storage!
    end
  end
end
