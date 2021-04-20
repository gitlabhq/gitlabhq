# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # migrates pages from legacy storage to zip format
    # we intentionally use application code here because
    # it has a lot of dependencies including models, carrierwave uploaders and service objects
    # and copying all or part of this code in the background migration doesn't add much value
    # see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54578 for discussion
    class MigratePagesToZipStorage
      def perform(start_id, stop_id)
        ::Pages::MigrateFromLegacyStorageService.new(Gitlab::AppLogger,
                                                     ignore_invalid_entries: false,
                                                     mark_projects_as_not_deployed: false)
          .execute_for_batch(start_id..stop_id)
      end
    end
  end
end
