# frozen_string_literal: true

module Mutations
  # This concern is deprecated and will be deleted in 14.6
  #
  # Use the SpamProtection concern instead.
  module CanMutateSpammable
    extend ActiveSupport::Concern

    DEPRECATION_NOTICE = {
      reason: 'Use spam protection with HTTP headers instead',
      milestone: '13.11'
    }.freeze

    included do
      argument :captcha_response, GraphQL::Types::String,
               required: false,
               deprecated: DEPRECATION_NOTICE,
               description: 'A valid CAPTCHA response value obtained by using the provided captchaSiteKey with a CAPTCHA API to present a challenge to be solved on the client. Required to resubmit if the previous operation returned "NeedsCaptchaResponse: true".'

      argument :spam_log_id, GraphQL::Types::Int,
               required: false,
               deprecated: DEPRECATION_NOTICE,
               description: 'The spam log ID which must be passed along with a valid CAPTCHA response for the operation to be completed. Required to resubmit if the previous operation returned "NeedsCaptchaResponse: true".'

      field :spam,
            GraphQL::Types::Boolean,
            null: true,
            deprecated: DEPRECATION_NOTICE,
            description: 'Indicates whether the operation was detected as definite spam. There is no option to resubmit the request with a CAPTCHA response.'

      field :needs_captcha_response,
            GraphQL::Types::Boolean,
            null: true,
            deprecated: DEPRECATION_NOTICE,
            description: 'Indicates whether the operation was detected as possible spam and not completed. If CAPTCHA is enabled, the request must be resubmitted with a valid CAPTCHA response and spam_log_id included for the operation to be completed. Included only when an operation was not completed because "NeedsCaptchaResponse" is true.'

      field :spam_log_id,
            GraphQL::Types::Int,
            null: true,
            deprecated: DEPRECATION_NOTICE,
            description: 'The spam log ID which must be passed along with a valid CAPTCHA response for an operation to be completed. Included only when an operation was not completed because "NeedsCaptchaResponse" is true.'

      field :captcha_site_key,
            GraphQL::Types::String,
            null: true,
            deprecated: DEPRECATION_NOTICE,
            description: 'The CAPTCHA site key which must be used to render a challenge for the user to solve to obtain a valid captchaResponse value. Included only when an operation was not completed because "NeedsCaptchaResponse" is true.'
    end
  end
end
