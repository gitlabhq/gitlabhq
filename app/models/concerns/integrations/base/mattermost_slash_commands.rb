# frozen_string_literal: true

module Integrations
  module Base
    module MattermostSlashCommands
      extend ActiveSupport::Concern

      MATTERMOST_URL = '%{ORIGIN}/%{TEAM}/channels/%{CHANNEL}'

      class_methods do
        def title
          s_('Integrations|Mattermost slash commands')
        end

        def description
          s_('Integrations|Perform common tasks with slash commands.')
        end

        def to_param
          'mattermost_slash_commands'
        end
      end

      included do
        include Base::SlashCommands
        include ::Ci::TriggersHelper

        field :token,
          type: :password,
          description: -> { _('The Mattermost token.') },
          non_empty_password_title: -> { s_('ProjectService|Enter new token') },
          non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
          required: true,
          placeholder: ''

        def testable?
          false
        end

        def avatar_url
          ActionController::Base.helpers.image_path('illustrations/third-party-logos/integrations-logos/mattermost.svg')
        end

        def configure(user, params)
          token = ::Mattermost::Command
            .new(user)
            .create(command(params))

          update(active: true, token: token) if token
        rescue ::Mattermost::Error => e
          [false, e.message]
        end

        def list_teams(current_user)
          [::Mattermost::Team.new(current_user).all, nil]
        rescue ::Mattermost::Error => e
          [[], e.message]
        end

        def redirect_url(team, channel, url)
          return if Gitlab::HTTP_V2::UrlBlocker.blocked_url?(
            url,
            schemes: %w[http https],
            enforce_sanitization: true,
            deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
            outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist) # rubocop:disable Naming/InclusiveLanguage -- existing setting

          origin = Addressable::URI.parse(url).origin
          format(MATTERMOST_URL, ORIGIN: origin, TEAM: team, CHANNEL: channel)
        end

        def confirmation_url(command_id, params)
          team, channel, response_url = params.values_at(:team_domain, :channel_name, :response_url)

          Rails.application.routes.url_helpers.project_integrations_slash_commands_url(
            project,
            command_id: command_id,
            integration: to_param,
            team: team,
            channel: channel,
            response_url: response_url
          )
        end

        private

        def command(params)
          pretty_project_name = project.full_name

          params.merge(
            auto_complete: true,
            auto_complete_desc: "Perform common operations on: #{pretty_project_name}",
            auto_complete_hint: '[help]',
            description: "Perform common operations on: #{pretty_project_name}",
            display_name: "GitLab / #{pretty_project_name}",
            method: 'P',
            username: 'GitLab'
          )
        end
      end
    end
  end
end
