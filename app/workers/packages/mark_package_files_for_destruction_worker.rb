# frozen_string_literal: true

module Packages
  class MarkPackageFilesForDestructionWorker
    include ApplicationWorker

    data_consistency :sticky
    queue_namespace :package_cleanup
    feature_category :package_registry
    urgency :low
    deduplicate :until_executing, including_scheduled: true
    idempotent!

    sidekiq_options retry: 3

    def perform(package_id)
      package = ::Packages::Package.find_by_id(package_id)

      return unless package

      ::Packages::MarkPackageFilesForDestructionService.new(package.package_files)
                                                       .execute
    end
  end
end
