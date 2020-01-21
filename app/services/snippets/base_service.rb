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
  end
end
