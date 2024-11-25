# frozen_string_literal: true

module Integrations
  class SlackSlashCommands < Integration
    include Base::SlashCommands
    include Ci::TriggersHelper

    SLACK_REDIRECT_URL = 'slack://channel?team=%{TEAM}&id=%{CHANNEL}'

    field :token,
      type: :password,
      description: -> { _('The Slack token.') },
      non_empty_password_title: -> { s_('ProjectService|Enter new token') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
      placeholder: '',
      required: true

    def self.title
      'Slack slash commands'
    end

    def self.description
      "Perform common operations in Slack."
    end

    def self.to_param
      'slack_slash_commands'
    end

    def trigger(params)
      # Format messages to be Slack-compatible
      super.tap do |result|
        result[:text] = format(result[:text]) if result.is_a?(Hash)
      end
    end

    def redirect_url(team, channel, _url)
      Kernel.format(SLACK_REDIRECT_URL, TEAM: team, CHANNEL: channel)
    end

    def confirmation_url(command_id, params)
      team, channel, response_url = params.values_at(:team_id, :channel_id, :response_url)

      Rails.application.routes.url_helpers.project_integrations_slash_commands_url(
        project, command_id: command_id, integration: to_param, team: team, channel: channel, response_url: response_url
      )
    end

    private

    def format(text)
      ::Slack::Messenger::Util::LinkFormatter.format(text) if text
    end
  end
end
