# frozen_string_literal: true

module Search
  module SearchRateLimitable
    extend ActiveSupport::Concern
    include Gitlab::Graphql::Authorize::AuthorizeResource

    # Implement scope and search_params methods in the class which includes this concern.
    def verify_search_rate_limit!(**args)
      if current_user
        key = :search_rate_limit
        scope = [current_user, safe_search_scope(**args)].compact
        users_allowlist = Gitlab::CurrentSettings.current_application_settings.search_rate_limit_allowlist
      else
        key = :search_rate_limit_unauthenticated
        scope = [context[:request].ip]
        users_allowlist = nil
      end

      if ::Gitlab::ApplicationRateLimiter.throttled_request?(
        context[:request], current_user, key, scope: scope, users_allowlist: users_allowlist
      )
        error_msg = <<~ERR.squish
              _('This endpoint has been requested too many times. Try again later.')
        ERR
        raise_resource_not_available_error!(error_msg)
      end
    end

    private

    def safe_search_scope(**args)
      # Sometimes search scope can have abusive length or invalid keyword. We don't want
      # to send those to redis for rate limit checks, so we guard against that here.
      scope unless Gitlab::Search::Params.new(search_params(**args)).abusive?
    end
  end
end
