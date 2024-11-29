# frozen_string_literal: true

# Base module for ChatOps integrations
module Integrations
  module Base
    module SlashCommands
      extend ActiveSupport::Concern

      CACHE_KEY = "slash-command-requests:%{secret}"
      CACHE_EXPIRATION_TIME = 3.minutes

      class_methods do
        def supported_events
          %w[]
        end
      end

      included do
        attribute :category, default: 'chat'
      end

      def trigger(params)
        return unless valid_token?(params[:token])

        chat_user = find_chat_user(params)
        user = chat_user&.user

        return unknown_user_message(params) unless user

        unless user.can?(:use_slash_commands)
          return Gitlab::SlashCommands::Presenters::Access.new.deactivated if user.deactivated?

          return Gitlab::SlashCommands::Presenters::Access.new.access_denied(project)
        end

        if Gitlab::SlashCommands::VerifyRequest.new(self, chat_user).valid?
          Gitlab::SlashCommands::Command.new(project, chat_user, params).execute
        else
          command_id = cache_slash_commands_request!(params)
          Gitlab::SlashCommands::Presenters::Access.new.confirm(confirmation_url(command_id, params))
        end
      end

      def valid_token?(token)
        respond_to?(:token) &&
          self.token.present? &&
          ActiveSupport::SecurityUtils.secure_compare(token, self.token)
      end

      def testable?
        false
      end

      private

      def find_chat_user(params)
        ChatNames::FindUserService.new(params[:team_id], params[:user_id]).execute
      end

      def authorize_chat_name_url(params)
        ChatNames::AuthorizeUserService.new(params).execute
      end

      def unknown_user_message(params)
        url = authorize_chat_name_url(params)
        Gitlab::SlashCommands::Presenters::Access.new(url).authorize
      end

      def cache_slash_commands_request!(params)
        secret = SecureRandom.uuid
        Kernel.format(CACHE_KEY, secret: secret).tap do |cache_key|
          Rails.cache.write(cache_key, params, expires_in: CACHE_EXPIRATION_TIME)
        end

        secret
      end
    end
  end
end
