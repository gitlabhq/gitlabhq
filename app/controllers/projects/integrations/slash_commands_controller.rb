# frozen_string_literal: true

module Projects
  module Integrations
    class SlashCommandsController < Projects::ApplicationController
      before_action :authenticate_user!

      feature_category :integrations

      def show
        @redirect_url = integration_redirect_url

        unless valid_request?
          @error = s_("Integrations|The slash command verification request has expired. Please run the command again.")
          return
        end

        return if valid_user? || @redirect_url.blank?

        @error = s_("Integrations|The slash command request is invalid.")
      end

      def confirm
        if valid_request? && valid_user?
          Gitlab::SlashCommands::VerifyRequest.new(integration, chat_user, request_params[:response_url]).approve!
          redirect_to request_params[:redirect_url]
        else
          @error = s_("Integrations|The slash command request is invalid.")
          render :show
        end
      end

      private

      def request_params
        params.permit(:integration, :team, :channel, :response_url, :command_id, :redirect_url)
      end

      def cached_params
        @cached_params ||= Rails.cache.fetch(cache_key)
      end

      def cache_key
        @cache_key ||= Kernel.format(
          ::Integrations::Base::SlashCommands::CACHE_KEY,
          secret: request_params[:command_id]
        )
      end

      def integration
        integration = request_params[:integration]

        case integration
        when 'slack_slash_commands'
          project.slack_slash_commands_integration
        when 'mattermost_slash_commands'
          project.mattermost_slash_commands_integration
        end
      end

      def integration_redirect_url
        return unless integration

        team, channel, url = request_params.values_at(:team, :channel, :response_url)

        integration.redirect_url(team, channel, url)
      end

      def valid_request?
        cached_params.present?
      end

      def valid_user?
        return false unless chat_user

        current_user == chat_user.user
      end

      def chat_user
        @chat_user ||= ChatNames::FindUserService.new(cached_params[:team_id], cached_params[:user_id]).execute
      end
    end
  end
end
