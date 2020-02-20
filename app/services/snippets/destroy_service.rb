# frozen_string_literal: true

module Snippets
  class DestroyService
    include Gitlab::Allowable

    attr_reader :current_user, :project

    def initialize(user, snippet)
      @current_user = user
      @snippet = snippet
      @project = snippet&.project
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

      if snippet.destroy
        ServiceResponse.success(message: 'Snippet was deleted.')
      else
        service_response_error('Failed to remove snippet.', 400)
      end
    end

    private

    attr_reader :snippet

    def user_can_delete_snippet?
      can?(current_user, :admin_snippet, snippet)
    end

    def service_response_error(message, http_status)
      ServiceResponse.error(message: message, http_status: http_status)
    end
  end
end
