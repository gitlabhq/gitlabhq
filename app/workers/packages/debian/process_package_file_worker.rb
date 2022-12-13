# frozen_string_literal: true

module Packages
  module Debian
    class ProcessPackageFileWorker
      include ApplicationWorker
      include ::Packages::FIPS
      include Gitlab::Utils::StrongMemoize

      data_consistency :always

      deduplicate :until_executed
      idempotent!

      queue_namespace :package_repositories
      feature_category :package_registry

      def perform(package_file_id, user_id, distribution_name, component_name)
        raise DisabledError, 'Debian registry is not FIPS compliant' if Gitlab::FIPS.enabled?

        @package_file_id = package_file_id
        @user_id = user_id
        @distribution_name = distribution_name
        @component_name = component_name

        return unless package_file && user && distribution_name && component_name
        # return if file has already been processed
        return unless package_file.debian_file_metadatum&.unknown?

        ::Packages::Debian::ProcessPackageFileService.new(package_file, user, distribution_name, component_name).execute
      rescue StandardError => e
        raise if e.instance_of?(DisabledError)

        Gitlab::ErrorTracking.log_exception(e, package_file_id: @package_file_id, user_id: @user_id,
                                               distribution_name: @distribution_name, component_name: @component_name)
        package_file.destroy!
      end

      private

      def package_file
        ::Packages::PackageFile.find_by_id(@package_file_id)
      end
      strong_memoize_attr :package_file

      def user
        ::User.find_by_id(@user_id)
      end
      strong_memoize_attr :user
    end
  end
end
