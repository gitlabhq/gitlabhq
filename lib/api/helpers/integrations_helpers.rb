# frozen_string_literal: true

module API
  module Helpers
    # Helpers module for API::Integrations
    #
    # The data structures inside this model are returned using class methods,
    # allowing EE to extend them where necessary.
    module IntegrationsHelpers
      def self.chat_notification_flags
        [
          {
            required: false,
            name: :notify_only_broken_pipelines,
            type: ::Grape::API::Boolean,
            desc: 'Send notifications for broken pipelines'
          }
        ].freeze
      end

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
          'apple-app-store' => ::Integrations::AppleAppStore.api_fields,
          'asana' => ::Integrations::Asana.api_fields,
          'assembla' => ::Integrations::Assembla.api_fields,
          'bamboo' => ::Integrations::Bamboo.api_fields,
          'bugzilla' => ::Integrations::Bugzilla.api_fields,
          'buildkite' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'Buildkite project GitLab token'
            },
            {
              required: true,
              name: :project_url,
              type: String,
              desc: 'The Buildkite pipeline URL'
            },
            {
              required: false,
              name: :enable_ssl_verification,
              type: ::Grape::API::Boolean,
              desc: 'DEPRECATED: This parameter has no effect since SSL verification will always be enabled'
            }
          ],
          'campfire' => ::Integrations::Campfire.api_fields,
          'confluence' => ::Integrations::Confluence.api_fields,
          'custom-issue-tracker' => ::Integrations::CustomIssueTracker.api_fields,
          'datadog' => [
            {
              required: true,
              name: :api_key,
              type: String,
              desc: 'API key used for authentication with Datadog'
            },
            {
              required: false,
              name: :datadog_site,
              type: String,
              desc: 'The Datadog site to send data to. To send data to the EU site, use datadoghq.eu'
            },
            {
              required: false,
              name: :api_url,
              type: String,
              desc: '(Advanced) The full URL for your Datadog site'
            },
            {
              required: false,
              name: :archive_trace_events,
              type: ::Grape::API::Boolean,
              desc: 'When enabled, job logs will be collected by Datadog and shown along pipeline execution traces'
            },
            {
              required: false,
              name: :datadog_service,
              type: String,
              desc: 'Tag all data from this GitLab instance in Datadog. Useful when managing several self-managed deployments'
            },
            {
              required: false,
              name: :datadog_env,
              type: String,
              desc: 'For self-managed deployments, set the env tag for all the data sent to Datadog'
            },
            {
              required: false,
              name: :datadog_tags,
              type: String,
              desc: 'Custom tags in Datadog. Specify one tag per line in the format: "key:value\nkey2:value2"'
            }
          ],
          'diffblue-cover' => ::Integrations::DiffblueCover.api_fields,
          'discord' => [
            ::Integrations::Discord.api_fields,
            chat_notification_flags,
            chat_notification_channels
          ].flatten,
          'drone-ci' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'Drone CI token'
            },
            {
              required: true,
              name: :drone_url,
              type: String,
              desc: 'Drone CI URL'
            },
            {
              required: false,
              name: :enable_ssl_verification,
              type: ::Grape::API::Boolean,
              desc: 'Enable SSL verification'
            }
          ],
          'emails-on-push' => [
            {
              required: true,
              name: :recipients,
              type: String,
              desc: 'Comma-separated list of recipient email addresses'
            },
            {
              required: false,
              name: :disable_diffs,
              type: ::Grape::API::Boolean,
              desc: 'Disable code diffs'
            },
            {
              required: false,
              name: :send_from_committer_email,
              type: ::Grape::API::Boolean,
              desc: 'Send from committer'
            },
            {
              required: false,
              name: :branches_to_be_notified,
              type: String,
              desc: 'Branches for which notifications are to be sent'
            }
          ],
          'external-wiki' => ::Integrations::ExternalWiki.api_fields,
          'gitlab-slack-application' => [
            ::Integrations::GitlabSlackApplication.api_fields,
            chat_notification_channels
          ].flatten,
          'google-play' => ::Integrations::GooglePlay.api_fields,
          'hangouts-chat' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'The Hangouts Chat webhook. e.g. https://chat.googleapis.com/v1/spaces…'
            },
            {
              required: false,
              name: :branches_to_be_notified,
              type: String,
              desc: 'Branches for which notifications are to be sent'
            }
          ].flatten,
          'harbor' => ::Integrations::Harbor.api_fields,
          'irker' => [
            {
              required: true,
              name: :recipients,
              type: String,
              desc: 'Recipients/channels separated by whitespaces'
            },
            {
              required: false,
              name: :default_irc_uri,
              type: String,
              desc: 'Default: irc://irc.network.net:6697'
            },
            {
              required: false,
              name: :server_host,
              type: String,
              desc: 'Server host. Default localhost'
            },
            {
              required: false,
              name: :server_port,
              type: Integer,
              desc: 'Server port. Default 6659'
            },
            {
              required: false,
              name: :colorize_messages,
              type: ::Grape::API::Boolean,
              desc: 'Colorize messages'
            }
          ],
          'jenkins' => [
            {
              required: true,
              name: :jenkins_url,
              type: String,
              desc: 'Jenkins root URL like https://jenkins.example.com'
            },
            {
              required: false,
              name: :enable_ssl_verification,
              type: ::Grape::API::Boolean,
              desc: 'Enable SSL verification'
            },
            {
              required: true,
              name: :project_name,
              type: String,
              desc: 'The URL-friendly project name. Example: my_project_name'
            },
            {
              required: false,
              name: :username,
              type: String,
              desc: 'A user with access to the Jenkins server, if applicable'
            },
            {
              required: false,
              name: :password,
              type: String,
              desc: 'The password of the user'
            }
          ],
          'jira' => [
            {
              required: true,
              name: :url,
              type: String,
              desc: 'The base URL to the Jira instance web interface which is being linked to this GitLab project. E.g., https://jira.example.com'
            },
            {
              required: false,
              name: :api_url,
              type: String,
              desc: 'The base URL to the Jira instance API. Web URL value will be used if not set. E.g., https://jira-api.example.com'
            },
            {
              required: false,
              name: :jira_auth_type,
              type: Integer,
              desc: 'The authentication method to be used with Jira. `0` means Basic Authentication. `1` means Jira personal access token. Defaults to `0`'
            },
            {
              required: false,
              name: :username,
              type: String,
              desc: 'The email or username to be used with Jira. For Jira Cloud use an email, for Jira Data Center and Jira Server use a username. Required when using Basic authentication (`jira_auth_type` is `0`)'
            },
            {
              required: true,
              name: :password,
              type: String,
              desc: 'The Jira API token, password, or personal access token to be used with Jira. When your authentication method is Basic (`jira_auth_type` is `0`) use an API token for Jira Cloud, or a password for Jira Data Center or Jira Server. When your authentication method is Jira personal access token (`jira_auth_type` is `1`) use a personal access token'
            },
            {
              required: false,
              name: :jira_issue_transition_automatic,
              type: ::Grape::API::Boolean,
              desc: 'Enable automatic issue transitions'
            },
            {
              required: false,
              name: :jira_issue_transition_id,
              type: String,
              desc: 'The ID of one or more transitions for custom issue transitions'
            },
            {
              required: false,
              name: :jira_issue_prefix,
              type: String,
              desc: 'Prefix to match Jira issue keys'
            },
            {
              required: false,
              name: :jira_issue_regex,
              type: String,
              desc: 'Regular expression to match Jira issue keys'
            },
            {
              required: false,
              name: :comment_on_event_enabled,
              type: ::Grape::API::Boolean,
              desc: 'Enable comments inside Jira issues on each GitLab event (commit / merge request)'
            }
          ],
          'mattermost-slash-commands' => ::Integrations::MattermostSlashCommands.api_fields,
          'slack-slash-commands' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'The Slack token'
            }
          ],
          'packagist' => [
            {
              required: true,
              name: :username,
              type: String,
              desc: 'The username'
            },
            {
              required: true,
              name: :token,
              type: String,
              desc: 'The Packagist API token'
            },
            {
              required: false,
              name: :server,
              type: String,
              desc: 'The server'
            }
          ],
          'phorge' => ::Integrations::Phorge.api_fields,
          'pipelines-email' => [
            {
              required: true,
              name: :recipients,
              type: String,
              desc: 'Comma-separated list of recipient email addresses'
            },
            {
              required: false,
              name: :notify_only_broken_pipelines,
              type: ::Grape::API::Boolean,
              desc: 'Notify only broken pipelines'
            },
            {
              required: false,
              name: :notify_only_default_branch,
              type: ::Grape::API::Boolean,
              desc: 'Send notifications only for the default branch'
            },
            {
              required: false,
              name: :branches_to_be_notified,
              type: String,
              desc: 'Branches for which notifications are to be sent'
            }
          ],
          'pivotaltracker' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'The Pivotaltracker token'
            },
            {
              required: false,
              name: :restrict_to_branch,
              type: String,
              desc: 'Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches.'
            }
          ],
          'prometheus' => [
            {
              required: false,
              name: :manual_configuration,
              type: ::Grape::API::Boolean,
              desc: 'When enabled, the default settings will be overridden with your custom configuration'
            },
            {
              required: true,
              name: :api_url,
              type: String,
              desc: 'Prometheus API Base URL, like http://prometheus.example.com/'
            },
            {
              required: true,
              name: :google_iap_audience_client_id,
              type: String,
              desc: 'Client ID of the IAP-secured resource (looks like IAP_CLIENT_ID.apps.googleusercontent.com)'
            },
            {
              required: true,
              name: :google_iap_service_account_json,
              type: String,
              desc: 'Contents of the credentials.json file of your service account, like: { "type": "service_account", "project_id": ... }'
            }
          ],
          'pumble' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'The Pumble chat webhook. For example, https://api.pumble.com/workspaces/x/...'
            }
          ].flatten,
          'pushover' => [
            {
              required: true,
              name: :api_key,
              type: String,
              desc: 'The application key'
            },
            {
              required: true,
              name: :user_key,
              type: String,
              desc: 'The user key'
            },
            {
              required: true,
              name: :priority,
              type: String,
              desc: 'The priority'
            },
            {
              required: true,
              name: :device,
              type: String,
              desc: 'Leave blank for all active devices'
            },
            {
              required: true,
              name: :sound,
              type: String,
              desc: 'The sound of the notification'
            }
          ],
          'redmine' => ::Integrations::Redmine.api_fields,
          'ewm' => ::Integrations::Ewm.api_fields,
          'youtrack' => ::Integrations::Youtrack.api_fields,
          'clickup' => ::Integrations::Clickup.api_fields,
          'slack' => [
            ::Integrations::Slack.api_fields,
            chat_notification_channels
          ].flatten,
          'microsoft-teams' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'The Microsoft Teams webhook. e.g. https://outlook.office.com/webhook/…'
            },
            {
              required: false,
              name: :branches_to_be_notified,
              type: String,
              desc: 'Branches for which notifications are to be sent'
            },
            chat_notification_flags
          ].flatten,
          'mattermost' => [
            ::Integrations::Mattermost.api_fields,
            chat_notification_channels
          ].flatten,
          'teamcity' => [
            {
              required: true,
              name: :teamcity_url,
              type: String,
              desc: 'TeamCity root URL like https://teamcity.example.com'
            },
            {
              required: false,
              name: :enable_ssl_verification,
              type: ::Grape::API::Boolean,
              desc: 'Enable SSL verification'
            },
            {
              required: true,
              name: :build_type,
              type: String,
              desc: 'Build configuration ID'
            },
            {
              required: true,
              name: :username,
              type: String,
              desc: 'A user with permissions to trigger a manual build'
            },
            {
              required: true,
              name: :password,
              type: String,
              desc: 'The password of the user'
            }
          ],
          'telegram' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'The Telegram chat token. For example, 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11'
            },
            {
              required: true,
              name: :room,
              type: String,
              desc: 'Unique identifier for the target chat or username of the target channel (in the format @channelusername)'
            },
            {
              required: false,
              name: :thread,
              type: Integer,
              desc: 'Unique identifier for the target message thread (topic in a forum supergroup)'
            },
            {
              required: false,
              name: :branches_to_be_notified,
              type: String,
              desc: 'Branches for which notifications are to be sent.'
            },
            chat_notification_flags
          ].flatten,
          'unify-circuit' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'The Unify Circuit webhook. e.g. https://circuit.com/rest/v2/webhooks/incoming/…'
            }
          ].flatten,
          'webex-teams' => ::Integrations::WebexTeams.api_fields,
          'zentao' => [
            {
              required: true,
              name: :url,
              type: String,
              desc: 'The base URL to the ZenTao instance web interface which is being linked to this GitLab project. For example, https://www.zentao.net'
            },
            {
              required: false,
              name: :api_url,
              type: String,
              desc: 'The base URL to the ZenTao instance API. Web URL value will be used if not set. For example, https://www.zentao.net'
            },
            {
              required: true,
              name: :api_token,
              type: String,
              desc: 'The API token created from ZenTao dashboard'
            },
            {
              required: true,
              name: :zentao_product_xid,
              type: String,
              desc: 'The product ID of ZenTao project'
            }
          ],
          'squash-tm' => ::Integrations::SquashTm.api_fields
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
          ::Integrations::Mattermost,
          ::Integrations::MattermostSlashCommands,
          ::Integrations::MicrosoftTeams,
          ::Integrations::Packagist,
          ::Integrations::Phorge,
          ::Integrations::PipelinesEmail,
          ::Integrations::Pivotaltracker,
          ::Integrations::Prometheus,
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
    end
  end
end

API::Helpers::IntegrationsHelpers.prepend_mod_with('API::Helpers::IntegrationsHelpers')
