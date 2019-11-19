# frozen_string_literal: true

module Gitlab
  class DeviseFailure < Devise::FailureApp
    include ::SessionsHelper

    # If the request format is not known, send a redirect instead of a 401
    # response, since this is the outcome we're most likely to want
    def http_auth?
      return super unless Feature.enabled?(:devise_redirect_unknown_formats, default_enabled: true)

      request_format && super
    end

    def respond
      limit_session_time

      super
    end
  end
end
