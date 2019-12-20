# frozen_string_literal: true

class CreateSnippetService < BaseService
  include SpamCheckService

  def execute
    filter_spam_check_params

    snippet = if project
                project.snippets.build(params)
              else
                PersonalSnippet.new(params)
              end

    unless Gitlab::VisibilityLevel.allowed_for?(current_user, snippet.visibility_level)
      deny_visibility_level(snippet)
      return snippet
    end

    snippet.author = current_user

    spam_check(snippet, current_user)

    snippet_saved = snippet.with_transaction_returning_status do
      snippet.save && snippet.store_mentions!
    end

    if snippet_saved
      UserAgentDetailService.new(snippet, @request).create
      Gitlab::UsageDataCounters::SnippetCounter.count(:create)
    end

    snippet
  end
end
