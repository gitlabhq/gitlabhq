# frozen_string_literal: true

module Packages
  module Nuget
    class ExtractionWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include ::Packages::ErrorHandling

      data_consistency :always

      sidekiq_options retry: 3

      queue_namespace :package_repositories
      feature_category :package_registry

      def perform(package_file_id, params = {})
        package_file = ::Packages::PackageFile.find_by_id(package_file_id)
        return unless package_file

        user_or_deploy_token =
          params[:user_id]&.then { |id| User.find_by_id(id) } ||
          params[:deploy_token_id]&.then { |id| DeployToken.find_by_id(id) }

        ::Packages::Nuget::ProcessPackageFileService.new(package_file, user_or_deploy_token).execute
      rescue StandardError => exception
        process_package_file_error(
          package_file: package_file,
          exception: exception
        )
      end
    end
  end
end
