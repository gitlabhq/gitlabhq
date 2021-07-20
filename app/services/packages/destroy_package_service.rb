# frozen_string_literal: true

module Packages
  class DestroyPackageService < BaseContainerService
    alias_method :package, :container

    def execute
      return service_response_error("You don't have access to this package", 403) unless user_can_delete_package?

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

    def user_can_delete_package?
      can?(current_user, :destroy_package, package.project)
    end
  end
end
