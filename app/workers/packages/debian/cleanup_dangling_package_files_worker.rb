# frozen_string_literal: true

module Packages
  module Debian
    class CleanupDanglingPackageFilesWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      data_consistency :sticky

      deduplicate :until_executed
      idempotent!

      feature_category :package_registry

      THREE_HOUR = 3.hours.freeze
      BATCH_TIMEOUT = 250.seconds.freeze

      def perform
        return unless Feature.enabled?(:debian_packages)

        package_files = Packages::PackageFile.with_debian_unknown_since(THREE_HOUR.ago)
                                             .installable

        Packages::MarkPackageFilesForDestructionService.new(package_files)
          .execute(batch_deadline: Time.zone.now + BATCH_TIMEOUT)
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e)
      end
    end
  end
end
