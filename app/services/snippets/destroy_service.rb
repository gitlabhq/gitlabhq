# frozen_string_literal: true

module Snippets
  class DestroyService
    include Gitlab::Allowable

    attr_reader :current_user, :snippet

    DestroyError = Class.new(StandardError)

    def initialize(user, snippet)
      @current_user = user
      @snippet = snippet
    end

    def execute
      if snippet.nil?
        return service_response_error('No snippet found.', 404)
      end

      unless user_can_delete_snippet?
        return service_response_error(
          "You don't have access to delete this snippet.",
          403
        )
      end

      attempt_destroy!

      ServiceResponse.success(message: 'Snippet was deleted.')
    rescue DestroyError
      service_response_error('Failed to remove snippet repository.', 400)
    rescue StandardError
      attempt_rollback_repository
      service_response_error('Failed to remove snippet.', 400)
    end

    private

    def attempt_destroy!
      result = Repositories::DestroyService.new(snippet.repository).execute

      raise DestroyError if result[:status] == :error

      snippet.destroy!
    end

    def attempt_rollback_repository
      Repositories::DestroyRollbackService.new(snippet.repository).execute
    end

    def user_can_delete_snippet?
      can?(current_user, :admin_snippet, snippet)
    end

    def service_response_error(message, http_status)
      ServiceResponse.error(message: message, http_status: http_status)
    end
  end
end

Snippets::DestroyService.prepend_mod_with('Snippets::DestroyService')
