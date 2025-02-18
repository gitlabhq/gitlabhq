# frozen_string_literal: true

module API
  module Helpers
    # Helpers module for API::Integrations
    #
    # The data structures inside this model are returned using class methods,
    # allowing EE to extend them where necessary.
    module IntegrationsHelpers
      def self.chat_notification_channels
        [
          {
            required: false,
            name: :push_channel,
            type: String,
            desc: 'The name of the channel to receive push_events notifications'
          },
          {
            required: false,
            name: :issue_channel,
            type: String,
            desc: 'The name of the channel to receive issues_events notifications'
          },
          {
            required: false,
            name: :incident_channel,
            type: String,
            desc: 'The name of the channel to receive incident_events notifications'
          },
          {
            required: false,
            name: :alert_channel,
            type: String,
            desc: 'The name of the channel to receive alert_events notifications'
          },
          {
            required: false,
            name: :confidential_issue_channel,
            type: String,
            desc: 'The name of the channel to receive confidential_issues_events notifications'
          },
          {
            required: false,
            name: :merge_request_channel,
            type: String,
            desc: 'The name of the channel to receive merge_requests_events notifications'
          },
          {
            required: false,
            name: :note_channel,
            type: String,
            desc: 'The name of the channel to receive note_events notifications'
          },
          {
            required: false,
            name: :confidential_note_channel,
            type: String,
            desc: 'The name of the channel to receive confidential_note_events notifications'
          },
          {
            required: false,
            name: :tag_push_channel,
            type: String,
            desc: 'The name of the channel to receive tag_push_events notifications'
          },
          {
            required: false,
            name: :deployment_channel,
            type: String,
            desc: 'The name of the channel to receive deployment_events notifications'
          },
          {
            required: false,
            name: :pipeline_channel,
            type: String,
            desc: 'The name of the channel to receive pipeline_events notifications'
          },
          {
            required: false,
            name: :wiki_page_channel,
            type: String,
            desc: 'The name of the channel to receive wiki_page_events notifications'
          }
        ].freeze
      end

      def self.integrations
        {
          'apple-app-store' => ::Integrations::AppleAppStore.api_arguments,
          'asana' => ::Integrations::Asana.api_arguments,
          'assembla' => ::Integrations::Assembla.api_arguments,
          'bamboo' => ::Integrations::Bamboo.api_arguments,
          'bugzilla' => ::Integrations::Bugzilla.api_arguments,
          'buildkite' => ::Integrations::Buildkite.api_arguments,
          'campfire' => ::Integrations::Campfire.api_arguments,
          'confluence' => ::Integrations::Confluence.api_arguments,
          'custom-issue-tracker' => ::Integrations::CustomIssueTracker.api_arguments,
          'datadog' => ::Integrations::Datadog.api_arguments,
          'diffblue-cover' => ::Integrations::DiffblueCover.api_arguments,
          'discord' => [
            ::Integrations::Discord.api_arguments,
            chat_notification_channels
          ].flatten,
          'drone-ci' => ::Integrations::DroneCi.api_arguments,
          'emails-on-push' => ::Integrations::EmailsOnPush.api_arguments,
          'external-wiki' => ::Integrations::ExternalWiki.api_arguments,
          'gitlab-slack-application' => [
            ::Integrations::GitlabSlackApplication.api_arguments,
            chat_notification_channels
          ].flatten,
          'google-play' => ::Integrations::GooglePlay.api_arguments,
          'hangouts-chat' => ::Integrations::HangoutsChat.api_arguments,
          'harbor' => ::Integrations::Harbor.api_arguments,
          'irker' => ::Integrations::Irker.api_arguments,
          'jenkins' => ::Integrations::Jenkins.api_arguments,
          'jira' => ::Integrations::Jira.api_arguments,
          'jira-cloud-app' => ::Integrations::JiraCloudApp.api_arguments,
          'matrix' => ::Integrations::Matrix.api_arguments,
          'mattermost-slash-commands' => ::Integrations::MattermostSlashCommands.api_arguments,
          'slack-slash-commands' => ::Integrations::SlackSlashCommands.api_arguments,
          'packagist' => ::Integrations::Packagist.api_arguments,
          'phorge' => ::Integrations::Phorge.api_arguments,
          'pipelines-email' => ::Integrations::PipelinesEmail.api_arguments,
          'pivotaltracker' => ::Integrations::Pivotaltracker.api_arguments,
          'pumble' => ::Integrations::Pumble.api_arguments,
          'pushover' => ::Integrations::Pushover.api_arguments,
          'redmine' => ::Integrations::Redmine.api_arguments,
          'ewm' => ::Integrations::Ewm.api_arguments,
          'youtrack' => ::Integrations::Youtrack.api_arguments,
          'clickup' => ::Integrations::Clickup.api_arguments,
          'slack' => [
            ::Integrations::Slack.api_arguments,
            chat_notification_channels
          ].flatten,
          'microsoft-teams' => ::Integrations::MicrosoftTeams.api_arguments,
          'mattermost' => [
            ::Integrations::Mattermost.api_arguments,
            chat_notification_channels
          ].flatten,
          'teamcity' => ::Integrations::Teamcity.api_arguments,
          'telegram' => ::Integrations::Telegram.api_arguments,
          'unify-circuit' => ::Integrations::UnifyCircuit.api_arguments,
          'webex-teams' => ::Integrations::WebexTeams.api_arguments,
          'zentao' => ::Integrations::Zentao.api_arguments,
          'squash-tm' => ::Integrations::SquashTm.api_arguments
        }
      end

      def self.integration_classes
        [
          ::Integrations::AppleAppStore,
          ::Integrations::Asana,
          ::Integrations::Assembla,
          ::Integrations::Bamboo,
          ::Integrations::Bugzilla,
          ::Integrations::Buildkite,
          ::Integrations::Campfire,
          ::Integrations::Clickup,
          ::Integrations::Confluence,
          ::Integrations::CustomIssueTracker,
          ::Integrations::Datadog,
          ::Integrations::DiffblueCover,
          ::Integrations::Discord,
          ::Integrations::DroneCi,
          ::Integrations::EmailsOnPush,
          ::Integrations::Ewm,
          ::Integrations::ExternalWiki,
          ::Integrations::GitlabSlackApplication,
          ::Integrations::GooglePlay,
          ::Integrations::HangoutsChat,
          ::Integrations::Harbor,
          ::Integrations::Irker,
          ::Integrations::Jenkins,
          ::Integrations::Jira,
          ::Integrations::JiraCloudApp,
          ::Integrations::Matrix,
          ::Integrations::Mattermost,
          ::Integrations::MattermostSlashCommands,
          ::Integrations::MicrosoftTeams,
          ::Integrations::Packagist,
          ::Integrations::Phorge,
          ::Integrations::PipelinesEmail,
          ::Integrations::Pivotaltracker,
          ::Integrations::Pumble,
          ::Integrations::Pushover,
          ::Integrations::Redmine,
          ::Integrations::Slack,
          ::Integrations::SlackSlashCommands,
          ::Integrations::SquashTm,
          ::Integrations::Teamcity,
          ::Integrations::Telegram,
          ::Integrations::UnifyCircuit,
          ::Integrations::WebexTeams,
          ::Integrations::Youtrack,
          ::Integrations::Zentao
        ]
      end

      def self.development_integration_classes
        [
          ::Integrations::MockCi,
          ::Integrations::MockMonitoring
        ]
      end

      def self.inheritance_field
        {
          required: false,
          name: :use_inherited_settings,
          type: ::Grape::API::Boolean,
          desc: 'Indicates whether to inherit the default settings. Defaults to `false`.'
        }
      end
    end
  end
end

API::Helpers::IntegrationsHelpers.prepend_mod_with('API::Helpers::IntegrationsHelpers')
