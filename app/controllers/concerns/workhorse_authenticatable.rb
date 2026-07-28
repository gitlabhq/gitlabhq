# frozen_string_literal: true

# Provides `verify_workhorse_api!` for the Rails app. The method asserts that
# the current request carried a fresh `Gitlab-Workhorse-Api-Request` JWT,
# meaning it transited Workhorse and Workhorse is therefore willing to honour
# the resulting `Gitlab-Workhorse-Send-Data` response payload (Gitaly
# credentials, pre-signed object storage URLs, downstream service tokens).
#
# The concern is included once in `ApplicationController`, so
# `verify_workhorse_api!` is available everywhere. **Do not call it from
# `before_action` blocks on every senddata-emitting controller**. The
# canonical chokepoint is the response-writing helper in
# `app/helpers/workhorse_helper.rb`; that helper calls `verify_workhorse_api!`
# itself, so a missed `before_action` cannot leak senddata.
#
# The `rescue_from JWT::DecodeError` defined in the concern delegates to
# `render_403`, which performs format negotiation (the styled
# `errors/access_denied` template for HTML clients, `head :forbidden` for
# everything else). Controllers that deliberately want to surface the JWT
# diagnostic in their response body (notably `Repositories::GitHttpController`
# via `render_403_with_exception`, for Git CLI UX) register their own
# `rescue_from JWT::DecodeError`. Rails searches rescue_from handlers in
# reverse registration order, so a handler registered later (in a subclass or
# in a concern included after this one) takes precedence.
module WorkhorseAuthenticatable
  extend ActiveSupport::Concern

  included do
    rescue_from JWT::DecodeError do
      render_403
    end
  end

  private

  def verify_workhorse_api!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end
end
