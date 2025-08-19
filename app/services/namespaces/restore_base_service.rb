# frozen_string_literal: true

module Namespaces
  class RestoreBaseService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    DELETED_SUFFIX_REGEX = /
      -
      (#{MarkForDeletionBaseService::LEGACY_DELETION_SCHEDULED_PATH_INFIX}
        |#{MarkForDeletionBaseService::DELETION_SCHEDULED_PATH_INFIX})
      -
      \d+\z
    /x

    def initialize(resource, user, params = {})
      @resource = resource
      @current_user = user
      @params = params.dup
    end

    def execute
      result = preconditions_checks
      return result if result.error?

      result = execute_restore

      if result.success?
        log_event
        post_success
      end

      result
    end

    private

    attr_reader :resource

    def remove_permission
      raise NotImplementedError
    end

    def resource_name
      raise NotImplementedError
    end

    def preconditions_checks
      return UnauthorizedError unless can?(current_user, remove_permission, resource)
      return not_marked_for_deletion_error unless resource.self_deletion_scheduled?
      return deletion_in_progress_error if resource.self_deletion_in_progress?

      ServiceResponse.success
    end

    def not_marked_for_deletion_error
      ServiceResponse.error(message: "#{resource_name.titleize} has not been marked for deletion")
    end

    def deletion_in_progress_error
      ServiceResponse.error(message: "#{resource_name.titleize} deletion is in progress")
    end

    # Can be overridden
    def post_success
      resource.reset
    end

    def updated_value(value)
      "#{original_value(value)}#{suffix}"
    end

    def original_value(value)
      value.sub(DELETED_SUFFIX_REGEX, '')
    end

    def suffix
      original_path_taken? ? "-#{SecureRandom.alphanumeric(5)}" : ""
    end
    strong_memoize_attr :suffix

    def original_path_taken?
      existing_resource = resource.class.find_by_full_path(original_value(resource.full_path))

      existing_resource.present? && existing_resource.id != resource.id
    end

    def log_event
      log_info("User #{current_user.id} restored #{resource_name} #{resource.full_path}")
    end
  end
end

Namespaces::RestoreBaseService.prepend_mod
