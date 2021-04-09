# frozen_string_literal: true

module Mutations
  # This concern can be mixed into a mutation to provide support for spam checking,
  # and optionally support the workflow to allow clients to display and solve CAPTCHAs.
  module SpamProtection
    extend ActiveSupport::Concern
    include Spam::Concerns::HasSpamActionResponseFields

    SpamActionError = Class.new(GraphQL::ExecutionError)
    NeedsCaptchaResponseError = Class.new(SpamActionError)
    SpamDisallowedError = Class.new(SpamActionError)

    NEEDS_CAPTCHA_RESPONSE_MESSAGE = "Request denied. Solve CAPTCHA challenge and retry"
    SPAM_DISALLOWED_MESSAGE = "Request denied. Spam detected"

    private

    # additional_spam_params    -> hash
    #
    # Used from a spammable mutation's #resolve method to generate
    # the required additional spam/CAPTCHA params which must be merged into the params
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

    def spam_action_response(object)
      fields = spam_action_response_fields(object)

      # If the SpamActionService detected something as spam,
      # this is non-recoverable and the needs_captcha_response
      # should not be considered
      kind = if fields[:spam]
               :spam
             elsif fields[:needs_captcha_response]
               :needs_captcha_response
             end

      [kind, fields]
    end

    def check_spam_action_response!(object)
      kind, fields = spam_action_response(object)

      case kind
      when :needs_captcha_response
        fields.delete :spam
        raise NeedsCaptchaResponseError.new(NEEDS_CAPTCHA_RESPONSE_MESSAGE, extensions: fields)
      when :spam
        raise SpamDisallowedError.new(SPAM_DISALLOWED_MESSAGE, extensions: { spam: true })
      else
        nil
      end
    end
  end
end
