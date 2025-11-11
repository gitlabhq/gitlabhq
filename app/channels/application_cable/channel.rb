# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    include Logging
    include Gitlab::Auth::AuthFinders

    before_subscribe :validate_user_authorization
    periodically :validate_user_authorization, every: 10.minutes

    def validate_user_authorization
      raise Gitlab::Auth::AuthenticationError unless Ability.allowed?(current_user, :access_api)

      validate_and_save_access_token!(scopes: authorization_scopes, reset_token: true)
    rescue Gitlab::Auth::AuthenticationError
      handle_authentication_error
    end

    def authorization_scopes
      [:api, :read_api]
    end

    private

    def client_subscribed?
      !subscription_rejected? && subscription_confirmation_sent?
    end

    def handle_authentication_error
      if client_subscribed?
        unsubscribe_from_channel
      else
        reject
      end
    end

    def notification_payload(_)
      super.merge!(params: params.except(:channel))
    end

    def request
      connection.request
    end
  end
end
