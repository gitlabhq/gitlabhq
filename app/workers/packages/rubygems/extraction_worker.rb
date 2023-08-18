# frozen_string_literal: true

module Packages
  module Rubygems
    class ExtractionWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include ::Packages::ErrorHandling

      data_consistency :always

      sidekiq_options retry: 3

      queue_namespace :package_repositories
      feature_category :package_registry
      deduplicate :until_executing

      def perform(package_file_id)
        package_file = ::Packages::PackageFile.find_by_id(package_file_id)

        return unless package_file

        ::Packages::Rubygems::ProcessGemService.new(package_file).execute
      rescue StandardError => exception
        process_package_file_error(
          package_file: package_file,
          exception: exception
        )
      end
    end
  end
end
