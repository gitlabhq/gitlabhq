# frozen_string_literal: true

module SearchRateLimitable
  extend ActiveSupport::Concern

  private

  def check_search_rate_limit!
    if current_user
      # Because every search in the UI typically runs concurrent searches with different
      # scopes to get counts, we apply rate limits on the search scope if it is present.
      #
      # If abusive search is detected, we have stricter limits and ignore the search scope.
      check_rate_limit!(:search_rate_limit, scope: [current_user, safe_search_scope].compact,
        users_allowlist: Gitlab::CurrentSettings.current_application_settings.search_rate_limit_allowlist)
    else
      check_rate_limit!(:search_rate_limit_unauthenticated, scope: [request.ip])
    end
  end

  def safe_search_scope
    # Sometimes search scope can have abusive length or invalid keyword. We don't want
    # to send those to redis for rate limit checks, so we guard against that here.
    params[:scope] unless abuse_detected?
  end

  def abuse_detected?
    Gitlab::Search::Params.new(params, detect_abuse: true).abusive?
  end
end
