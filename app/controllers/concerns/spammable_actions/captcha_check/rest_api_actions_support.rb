# frozen_string_literal: true

# This module should be included to support CAPTCHA check for REST API actions via Grape.
#
# If the request is directly handled by a controller action, then the corresponding module which
# supports HTML or JSON formats should be used instead.
module SpammableActions::CaptchaCheck::RestApiActionsSupport
  extend ActiveSupport::Concern
  include SpammableActions::CaptchaCheck::Common
  include Spam::Concerns::HasSpamActionResponseFields

  private

  def with_captcha_check_rest_api(spammable:, &block)
    # In the case of the REST API, the request is handled by Grape, so if there is a spam-related
    # error, we don't render directly, instead we will pass the error message and other necessary
    # fields to the Grape api error helper for it to handle.
    captcha_render_lambda = -> do
      fields = spam_action_response_fields(spammable)

      fields.delete :spam
      # NOTE: "409 - Conflict" seems to be the most appropriate HTTP status code for a response
      # which requires a CAPTCHA to be solved in order for the request to be resubmitted.
      # https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.10
      status = 409

      # NOTE: This nested 'error' key may not be consistent with all other API error responses,
      # because they are not currently consistent across different API endpoints
      # and models. Some (snippets) will nest errors in an errors key like this,
      # while others (issues) will return the model's errors hash without an errors key,
      # while still others just return a plain string error.
      # See https://gitlab.com/groups/gitlab-org/-/epics/5527#revisit-inconsistent-shape-of-error-responses-in-rest-api
      fields[:message] = { error: spammable.errors.full_messages.to_sentence }
      render_structured_api_error!(fields, status)
    end

    with_captcha_check_common(spammable: spammable, captcha_render_lambda: captcha_render_lambda, &block)
  end
end
