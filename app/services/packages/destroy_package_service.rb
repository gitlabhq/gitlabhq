# frozen_string_literal: true

module Packages
  class DestroyPackageService < BaseContainerService
    alias_method :package, :container

    def execute
      return service_response_error("You don't have access to this package", 403) unless user_can_delete_package?

      if too_many_package_files?
        return service_response_error("It's not possible to delete a package with more than #{max_package_files} #{'file'.pluralize(max_package_files)}.", 400)
      end

      package.destroy!

      package.sync_maven_metadata(current_user)

      service_response_success('Package was successfully deleted')
    rescue StandardError
      service_response_error('Failed to remove the package', 400)
    end

    private

    def service_response_error(message, http_status)
      ServiceResponse.error(message: message, http_status: http_status)
    end

    def service_response_success(message)
      ServiceResponse.success(message: message)
    end

    def too_many_package_files?
      max_package_files < package.package_files.limit(max_package_files + 1).count
    end

    def max_package_files
      ::Gitlab::CurrentSettings.current_application_settings.max_package_files_for_package_destruction
    end

    def user_can_delete_package?
      can?(current_user, :destroy_package, package.project)
    end
  end
end
