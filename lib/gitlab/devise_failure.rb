# frozen_string_literal: true

module Gitlab
  class DeviseFailure < Devise::FailureApp
    # If the request format is not known, send a redirect instead of a 401
    # response, since this is the outcome we're most likely to want
    def http_auth?
      request_format && super
    end

    def respond
      if warden_options[:reason] == :too_many_requests
        self.status = 403
      else
        super
      end
    end
  end
end

Gitlab::DeviseFailure.prepend_mod
