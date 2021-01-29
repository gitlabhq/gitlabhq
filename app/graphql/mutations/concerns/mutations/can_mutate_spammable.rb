# frozen_string_literal: true

module Mutations
  # This concern can be mixed into a mutation to provide support for spam checking,
  # and optionally support the workflow to allow clients to display and solve recaptchas.
  module CanMutateSpammable
    extend ActiveSupport::Concern

    included do
      field :spam,
            GraphQL::BOOLEAN_TYPE,
            null: true,
            description: 'Indicates whether the operation returns a record detected as spam.'
    end

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

    # with_spam_action_fields(spammable) { {other_fields: true} }    -> hash
    #
    # Takes a Spammable and a block as arguments.
    #
    # The block passed should be a hash, which the spam action fields will be merged into.
    def with_spam_action_fields(spammable)
      spam_action_fields = {
        spam: spammable.spam?,
        # NOTE: These fields are intentionally named with 'captcha' instead of 'recaptcha', so
        # that they can be applied to future alternative captcha implementations other than
        # reCAPTCHA (such as FriendlyCaptcha) without having to change the response field name
        # in the API.
        needs_captcha_response: spammable.render_recaptcha?,
        spam_log_id: spammable.spam_log&.id,
        captcha_site_key: Gitlab::CurrentSettings.recaptcha_site_key
      }

      yield.merge(spam_action_fields)
    end
  end
end
