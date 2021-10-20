# frozen_string_literal: true

module Packages
  module Composer
    class CacheUpdateWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: false

      feature_category :package_registry

      idempotent!

      def perform(*args)
        # no-op: to be removed after 14.5 https://gitlab.com/gitlab-org/gitlab/-/issues/333694
      end
    end
  end
end
