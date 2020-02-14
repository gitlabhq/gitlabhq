# frozen_string_literal: true

module Snippets
  class CreateService < Snippets::BaseService
    include SpamCheckMethods

    def execute
      filter_spam_check_params

      snippet = if project
                  project.snippets.build(params)
                else
                  PersonalSnippet.new(params)
                end

      unless Gitlab::VisibilityLevel.allowed_for?(current_user, snippet.visibility_level)
        deny_visibility_level(snippet)

        return snippet_error_response(snippet, 403)
      end

      snippet.author = current_user

      spam_check(snippet, current_user)

      snippet_saved = snippet.with_transaction_returning_status do
        snippet.save
      end

      if snippet_saved
        UserAgentDetailService.new(snippet, @request).create
        Gitlab::UsageDataCounters::SnippetCounter.count(:create)

        ServiceResponse.success(payload: { snippet: snippet } )
      else
        snippet_error_response(snippet, 400)
      end
    end
  end
end
