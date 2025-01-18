# frozen_string_literal: true

module Snippets
  class BulkDestroyService
    include Gitlab::Allowable

    attr_reader :current_user, :snippets

    DeleteRepositoryError = Class.new(StandardError)
    SnippetAccessError = Class.new(StandardError)

    def initialize(user, snippets)
      @current_user = user
      @snippets = snippets
    end

    def execute(skip_authorization: false)
      return ServiceResponse.success(message: 'No snippets found.') if snippets.empty?

      user_can_delete_snippets! unless skip_authorization
      attempt_delete_repositories!
      snippets.destroy_all # rubocop: disable Cop/DestroyAll

      ServiceResponse.success(message: 'Snippets were deleted.')
    rescue SnippetAccessError
      service_response_error("You don't have access to delete these snippets.", 403)
    rescue DeleteRepositoryError
      service_response_error('Failed to delete snippet repositories.', 400)
    rescue StandardError
      # In case the delete operation fails
      service_response_error('Failed to remove snippets.', 400)
    end

    private

    def user_can_delete_snippets!
      allowed = DeclarativePolicy.user_scope do
        snippets.find_each.all? { |snippet| user_can_delete_snippet?(snippet) }
      end

      raise SnippetAccessError unless allowed
    end

    def user_can_delete_snippet?(snippet)
      can?(current_user, :admin_snippet, snippet)
    end

    def attempt_delete_repositories!
      snippets.each do |snippet|
        result = ::Repositories::DestroyService.new(snippet.repository).execute

        raise DeleteRepositoryError if result[:status] == :error
      end
    end

    def service_response_error(message, http_status)
      ServiceResponse.error(message: message, http_status: http_status)
    end
  end
end
