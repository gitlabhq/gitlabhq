# frozen_string_literal: true

module Snippets
  class BaseService < ::BaseService
    private

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
  end
end
