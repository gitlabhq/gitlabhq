# frozen_string_literal: true

module Namespaces
  class MarkForDeletionBaseService < ::BaseService
    DELETION_SCHEDULED_PATH_INFIX = 'deletion_scheduled'
    LEGACY_DELETION_SCHEDULED_PATH_INFIX = 'deleted'

    def initialize(resource, user, params = {})
      @resource = resource
      @current_user = user
      @params = params.dup
    end

    def execute
      result = preconditions_checks
      return result if result.error?

      result = execute_deletion

      if result.success?
        log_event
        send_notification
        post_success
      else
        log_error(result.message)
      end

      result
    end

    private

    attr_reader :resource

    def remove_permission
      raise NotImplementedError
    end

    def notification_method
      raise NotImplementedError
    end

    def resource_name
      raise NotImplementedError
    end

    def preconditions_checks
      return UnauthorizedError unless can?(current_user, remove_permission, resource)
      return already_marked_error if resource.self_deletion_scheduled?

      ServiceResponse.success
    end

    def already_marked_error
      ServiceResponse.error(message: "#{resource_name.titleize} has been already marked for deletion")
    end

    # Can be overridden
    def post_success
      resource.reset
    end

    def suffixed_identifier(original_identifier)
      "#{original_identifier}-#{DELETION_SCHEDULED_PATH_INFIX}-#{resource.id}"
    end

    def log_event
      log_info("User #{current_user.id} marked #{resource_name} #{resource.full_path} for deletion")
    end

    def send_notification
      notification_service.public_send(notification_method, resource) # rubocop:disable GitlabSecurity/PublicSend -- We control the method name here.
    end
  end
end

Namespaces::MarkForDeletionBaseService.prepend_mod
