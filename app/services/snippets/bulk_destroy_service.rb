# frozen_string_literal: true

module Snippets
  class BulkDestroyService
    include Gitlab::Allowable

    NO_ACCESS_ERROR = {
      reason: :no_access_error,
      message: "You don't have access to delete these snippets."
    }.freeze

    SNIPPET_REPOSITORIES_DELETE_ERROR =
      { reason: :snippet_repositories_delete_error,
        message: 'Failed to delete snippet repositories.' }.freeze
    SNIPPETS_DELETE_ERROR = {
      reason: :snippet_delete_error,
      message: 'Failed to remove snippets.'
    }.freeze

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
      ServiceResponse.error(
        reason: NO_ACCESS_ERROR[:reason],
        message: NO_ACCESS_ERROR[:message]
      )
    rescue DeleteRepositoryError
      ServiceResponse.error(
        reason: SNIPPET_REPOSITORIES_DELETE_ERROR[:reason],
        message: SNIPPET_REPOSITORIES_DELETE_ERROR[:message]
      )
    rescue StandardError
      # In case the delete operation fails
      ServiceResponse.error(
        reason: SNIPPETS_DELETE_ERROR[:reason],
        message: SNIPPETS_DELETE_ERROR[:message]
      )
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
  end
end
