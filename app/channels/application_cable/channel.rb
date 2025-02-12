# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    include Logging
    include Gitlab::Auth::AuthFinders

    before_subscribe :validate_token_scope
    periodically :validate_token_scope, every: 10.minutes

    def validate_token_scope
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
