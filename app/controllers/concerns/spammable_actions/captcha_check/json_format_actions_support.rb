# frozen_string_literal: true

# This module should be included to support forms submits with a 'js' or 'json' type of MIME type.
# In other words, forms handled by actions which use a `respond_to` of `format.js` or `format.json`.
#
# For example, for all Javascript based form submissions and Vue components which use Apollo and Axios
# which are directly handled by a controller other than `GraphqlController`. For example, issue
# update currently uses this module.
#
# However, requests which directly hit `GraphqlController` will not use this module - the
# `Mutations::SpamProtection` module handles those requests (for example, snippet create/update
# requests)
#
# If the request is handled by actions via `format.html`, then the corresponding module which
# supports HTML format should be used instead.
module SpammableActions::CaptchaCheck::JsonFormatActionsSupport
  extend ActiveSupport::Concern
  include SpammableActions::CaptchaCheck::Common
  include Spam::Concerns::HasSpamActionResponseFields

  private

  def with_captcha_check_json_format(spammable:, &block)
    # NOTE: "409 - Conflict" seems to be the most appropriate HTTP status code for a response
    # which requires a CAPTCHA to be solved in order for the request to be resubmitted.
    # https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.10
    captcha_render_lambda = -> { render json: spam_action_response_fields(spammable), status: :conflict }
    with_captcha_check_common(spammable: spammable, captcha_render_lambda: captcha_render_lambda, &block)
  end
end
