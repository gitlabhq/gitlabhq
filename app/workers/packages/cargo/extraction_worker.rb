# frozen_string_literal: true

module Packages
  module Cargo
    class ExtractionWorker
      include ApplicationWorker
      include ::Packages::ErrorHandling

      data_consistency :sticky
      sidekiq_options retry: 3
      queue_namespace :package_repositories
      feature_category :package_registry
      idempotent!
      deduplicate :until_executed

      def perform(package_file_id, params = {})
        package_file = ::Packages::PackageFile.not_processing.find_by_id(package_file_id)
        return unless package_file

        user_or_deploy_token = User.find_by_id(params[:user_id]) if params.key?(:user_id)
        user_or_deploy_token = DeployToken.find_by_id(params[:deploy_token_id]) if params.key?(:deploy_token_id)

        return unless user_or_deploy_token

        ::Packages::Cargo::ProcessPackageFileService.new(package_file, user_or_deploy_token).execute
      rescue StandardError => exception
        raise exception unless package_file

        process_package_file_error(
          package_file: package_file,
          exception: exception
        )
      end
    end
  end
end
