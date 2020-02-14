# frozen_string_literal: true

module Snippets
  class UpdateService < Snippets::BaseService
    include SpamCheckMethods

    def execute(snippet)
      # check that user is allowed to set specified visibility_level
      new_visibility = visibility_level

      if new_visibility && new_visibility.to_i != snippet.visibility_level
        unless Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)
          deny_visibility_level(snippet, new_visibility)

          return snippet_error_response(snippet, 403)
        end
      end

      filter_spam_check_params
      snippet.assign_attributes(params)
      spam_check(snippet, current_user)

      snippet_saved = snippet.with_transaction_returning_status do
        snippet.save
      end

      if snippet_saved
        Gitlab::UsageDataCounters::SnippetCounter.count(:update)

        ServiceResponse.success(payload: { snippet: snippet } )
      else
        snippet_error_response(snippet, 400)
      end
    end
  end
end
