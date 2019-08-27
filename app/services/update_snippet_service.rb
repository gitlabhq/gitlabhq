# frozen_string_literal: true

class UpdateSnippetService < BaseService
  include SpamCheckService

  attr_accessor :snippet

  def initialize(project, user, snippet, params)
    super(project, user, params)
    @snippet = snippet
  end

  def execute
    # check that user is allowed to set specified visibility_level
    new_visibility = visibility_level

    if new_visibility && new_visibility.to_i != snippet.visibility_level
      unless Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)
        deny_visibility_level(snippet, new_visibility)
        return snippet
      end
    end

    filter_spam_check_params
    snippet.assign_attributes(params)
    spam_check(snippet, current_user)

    snippet.save.tap do |succeeded|
      Gitlab::UsageDataCounters::SnippetCounter.count(:update) if succeeded
    end
  end
end
