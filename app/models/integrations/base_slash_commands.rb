# frozen_string_literal: true

# Base class for ChatOps integrations
# This class is not meant to be used directly, but only to inherrit from.
module Integrations
  class BaseSlashCommands < Integration
    CACHE_KEY = "slash-command-requests:%{secret}"
    CACHE_EXPIRATION_TIME = 3.minutes

    attribute :category, default: 'chat'

    def valid_token?(token)
      self.respond_to?(:token) &&
        self.token.present? &&
        ActiveSupport::SecurityUtils.secure_compare(token, self.token)
    end

    def self.supported_events
      %w[]
    end

    def testable?
      false
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

    private

    def find_chat_user(params)
      ChatNames::FindUserService.new(params[:team_id], params[:user_id]).execute # rubocop: disable CodeReuse/ServiceClass -- This is not AR
    end

    def authorize_chat_name_url(params)
      ChatNames::AuthorizeUserService.new(params).execute # rubocop: disable CodeReuse/ServiceClass -- This is not AR
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
