# frozen_string_literal: true

module Snippets
  class BaseService < ::BaseService
    include SpamCheckMethods

    CreateRepositoryError = Class.new(StandardError)

    attr_reader :uploaded_assets, :snippet_files

    def initialize(project, user = nil, params = {})
      super

      @uploaded_assets = Array(@params.delete(:files).presence)
      @snippet_files = SnippetInputActionCollection.new(Array(@params.delete(:snippet_files).presence))

      filter_spam_check_params
    end

    private

    def visibility_allowed?(snippet, visibility_level)
      Gitlab::VisibilityLevel.allowed_for?(current_user, visibility_level)
    end

    def forbidden_visibility_error(snippet)
      deny_visibility_level(snippet)

      snippet_error_response(snippet, 403)
    end

    def valid_params?
      return true if snippet_files.empty?

      (params.keys & [:content, :file_name]).none? && snippet_files.valid?
    end

    def invalid_params_error(snippet)
      if snippet_files.valid?
        [:content, :file_name].each do |key|
          snippet.errors.add(key, 'and snippet files cannot be used together') if params.key?(key)
        end
      else
        snippet.errors.add(:snippet_files, 'have invalid data')
      end

      snippet_error_response(snippet, 403)
    end

    def snippet_error_response(snippet, http_status)
      ServiceResponse.error(
        message: snippet.errors.full_messages.to_sentence,
        http_status: http_status,
        payload: { snippet: snippet }
      )
    end

    def add_snippet_repository_error(snippet:, error:)
      message = repository_error_message(error)

      snippet.errors.add(:repository, message)
    end

    def repository_error_message(error)
      message = self.is_a?(Snippets::CreateService) ? _("Error creating the snippet") : _("Error updating the snippet")

      # We only want to include additional error detail in the message
      # if the error is not a CommitError because we cannot guarantee the message
      # will be user-friendly
      message += " - #{error.message}" unless error.instance_of?(SnippetRepository::CommitError)

      message
    end

    def files_to_commit(snippet)
      snippet_files.to_commit_actions.presence || build_actions_from_params(snippet)
    end

    def build_actions_from_params(snippet)
      raise NotImplementedError
    end
  end
end
