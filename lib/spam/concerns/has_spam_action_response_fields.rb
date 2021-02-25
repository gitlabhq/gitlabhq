# frozen_string_literal: true

module Spam
  module Concerns
    # This concern is shared by the controller and GraphQL layer to handle
    # addition of spam/CAPTCHA related fields in the response.
    module HasSpamActionResponseFields
      extend ActiveSupport::Concern

      # spam_action_response_fields(spammable)    -> hash
      #
      # Takes a Spammable as an argument and returns response fields necessary to display a CAPTCHA on
      # the client.
      def spam_action_response_fields(spammable)
        {
          spam: spammable.spam?,
          # NOTE: These fields are intentionally named with 'captcha' instead of 'recaptcha', so
          # that they can be applied to future alternative CAPTCHA implementations other than
          # reCAPTCHA (such as FriendlyCaptcha) without having to change the response field name
          # in the API.
          needs_captcha_response: spammable.render_recaptcha?,
          spam_log_id: spammable.spam_log&.id,
          captcha_site_key: Gitlab::CurrentSettings.recaptcha_site_key
        }
      end

      # with_spam_action_response_fields(spammable) { {other_fields: true} }    -> hash
      #
      # Takes a Spammable and a block as arguments.
      #
      # The block passed should be a hash, which the spam_action_fields will be merged into.
      def with_spam_action_response_fields(spammable)
        yield.merge(spam_action_response_fields(spammable))
      end
    end
  end
end
