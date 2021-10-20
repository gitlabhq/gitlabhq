# frozen_string_literal: true

module Packages
  module Composer
    class CacheCleanupWorker
      include ApplicationWorker

      data_consistency :always

      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      feature_category :package_registry

      idempotent!

      def perform
        # no-op: to be removed after 14.5 https://gitlab.com/gitlab-org/gitlab/-/issues/333694
      end
    end
  end
end
