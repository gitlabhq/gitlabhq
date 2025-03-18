# frozen_string_literal: true

module Packages
  module Nuget
    class CreateSymbolsWorker
      include ApplicationWorker
      include ::Packages::ErrorHandling

      data_consistency :sticky
      deduplicate :until_executed
      idempotent!

      queue_namespace :package_repositories
      feature_category :package_registry

      def perform(package_file_id)
        package_file = ::Packages::PackageFile.find_by_id(package_file_id)

        return unless package_file

        package_file.file.use_open_file(unlink_early: false) do |open_file|
          # rubocop: disable Performance/Rubyzip -- limited by the Packages::Nuget::Symbols::CreateSymbolFilesService
          Zip::File.open(open_file.file_path) do |zip_file|
            ::Packages::Nuget::Symbols::CreateSymbolFilesService
              .new(package_file.package, zip_file)
              .execute
          end
          # rubocop: enable Performance/Rubyzip
        end
      rescue StandardError => exception
        process_package_file_error(
          package_file: package_file,
          exception: exception
        )
      end
    end
  end
end
