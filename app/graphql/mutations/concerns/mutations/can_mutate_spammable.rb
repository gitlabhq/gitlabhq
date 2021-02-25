# frozen_string_literal: true

module Mutations
  # This concern can be mixed into a mutation to provide support for spam checking,
  # and optionally support the workflow to allow clients to display and solve CAPTCHAs.
  module CanMutateSpammable
    extend ActiveSupport::Concern
    include Spam::Concerns::HasSpamActionResponseFields

    # NOTE: The arguments and fields are intentionally named with 'captcha' instead of 'recaptcha',
    # so that they can be applied to future alternative CAPTCHA implementations other than
    # reCAPTCHA (e.g. FriendlyCaptcha) without having to change the names and descriptions in the API.
    included do
      argument :captcha_response, GraphQL::STRING_TYPE,
               required: false,
               description: 'A valid CAPTCHA response value obtained by using the provided captchaSiteKey with a CAPTCHA API to present a challenge to be solved on the client. Required to resubmit if the previous operation returned "NeedsCaptchaResponse: true".'

      argument :spam_log_id, GraphQL::INT_TYPE,
               required: false,
               description: 'The spam log ID which must be passed along with a valid CAPTCHA response for the operation to be completed. Required to resubmit if the previous operation returned "NeedsCaptchaResponse: true".'

      field :spam,
            GraphQL::BOOLEAN_TYPE,
            null: true,
            description: 'Indicates whether the operation was detected as definite spam. There is no option to resubmit the request with a CAPTCHA response.'

      field :needs_captcha_response,
            GraphQL::BOOLEAN_TYPE,
            null: true,
            description: 'Indicates whether the operation was detected as possible spam and not completed. If CAPTCHA is enabled, the request must be resubmitted with a valid CAPTCHA response and spam_log_id included for the operation to be completed. Included only when an operation was not completed because "NeedsCaptchaResponse" is true.'

      field :spam_log_id,
            GraphQL::INT_TYPE,
            null: true,
            description: 'The spam log ID which must be passed along with a valid CAPTCHA response for an operation to be completed. Included only when an operation was not completed because "NeedsCaptchaResponse" is true.'

      field :captcha_site_key,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'The CAPTCHA site key which must be used to render a challenge for the user to solve to obtain a valid captchaResponse value. Included only when an operation was not completed because "NeedsCaptchaResponse" is true.'
    end

    private

    # additional_spam_params    -> hash
    #
    # Used from a spammable mutation's #resolve method to generate
    # the required additional spam/recaptcha params which must be merged into the params
    # passed to the constructor of a service, where they can then be used in the service
    # to perform spam checking via SpamActionService.
    #
    # Also accesses the #context of the mutation's Resolver superclass to obtain the request.
    #
    # Example:
    #
    # existing_args.merge!(additional_spam_params)
    def additional_spam_params
      {
        api: true,
        request: context[:request]
      }
    end
  end
end
