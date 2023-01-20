# frozen_string_literal: true

module Packages
  module Debian
    class ProcessChangesWorker
      include ApplicationWorker

      data_consistency :always
      include Gitlab::Utils::StrongMemoize

      deduplicate :until_executed
      idempotent!

      queue_namespace :package_repositories
      feature_category :package_registry

      def perform(package_file_id, user_id)
        @package_file_id = package_file_id
        @user_id = user_id

        return unless package_file && user

        ::Packages::Debian::ProcessChangesService.new(package_file, user).execute
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, package_file_id: @package_file_id, user_id: @user_id)
        package_file.destroy!
      end

      private

      attr_reader :package_file_id, :user_id

      def package_file
        strong_memoize(:package_file) do
          ::Packages::PackageFile.find_by_id(package_file_id)
        end
      end

      def user
        strong_memoize(:user) do
          ::User.find_by_id(user_id)
        end
      end
    end
  end
end
