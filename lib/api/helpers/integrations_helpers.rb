# frozen_string_literal: true

module API
  module Helpers
    # Helpers module for API::Integrations
    #
    # The data structures inside this model are returned using class methods,
    # allowing EE to extend them where necessary.
    module IntegrationsHelpers
      def self.chat_notification_settings
        [
          {
            required: true,
            name: :webhook,
            type: String,
            desc: 'The chat webhook'
          },
          {
            required: false,
            name: :username,
            type: String,
            desc: 'The chat username'
          },
          {
            required: false,
            name: :channel,
            type: String,
            desc: 'The default chat channel'
          },
          {
            required: false,
            name: :branches_to_be_notified,
            type: String,
            desc: 'Branches for which notifications are to be sent'
          }
        ].freeze
      end

      def self.chat_notification_flags
        [
          {
            required: false,
            name: :notify_only_broken_pipelines,
            type: Boolean,
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
            name: :tag_push_channel,
            type: String,
            desc: 'The name of the channel to receive tag_push_events notifications'
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

      def self.chat_notification_events
        [
          {
            required: false,
            name: :push_events,
            type: Boolean,
            desc: 'Enable notifications for push_events'
          },
          {
            required: false,
            name: :issues_events,
            type: Boolean,
            desc: 'Enable notifications for issues_events'
          },
          {
            required: false,
            name: :incident_events,
            type: Boolean,
            desc: 'Enable notifications for incident_events'
          },
          {
            required: false,
            name: :confidential_issues_events,
            type: Boolean,
            desc: 'Enable notifications for confidential_issues_events'
          },
          {
            required: false,
            name: :merge_requests_events,
            type: Boolean,
            desc: 'Enable notifications for merge_requests_events'
          },
          {
            required: false,
            name: :note_events,
            type: Boolean,
            desc: 'Enable notifications for note_events'
          },
          {
            required: false,
            name: :confidential_note_events,
            type: Boolean,
            desc: 'Enable notifications for confidential_note_events'
          },
          {
            required: false,
            name: :tag_push_events,
            type: Boolean,
            desc: 'Enable notifications for tag_push_events'
          },
          {
            required: false,
            name: :pipeline_events,
            type: Boolean,
            desc: 'Enable notifications for pipeline_events'
          },
          {
            required: false,
            name: :wiki_page_events,
            type: Boolean,
            desc: 'Enable notifications for wiki_page_events'
          }
        ].freeze
      end

      def self.integrations
        {
          'apple-app-store' => [
            {
              required: true,
              name: :app_store_issuer_id,
              type: String,
              desc: 'The Apple App Store Connect Issuer ID'
            },
            {
              required: true,
              name: :app_store_key_id,
              type: String,
              desc: 'The Apple App Store Connect Key ID'
            },
            {
              required: true,
              name: :app_store_private_key,
              type: String,
              desc: 'The Apple App Store Connect Private Key'
            },
            {
              required: true,
              name: :app_store_private_key_file_name,
              type: String,
              desc: 'The Apple App Store Connect Private Key File Name'
            }
          ],
          'asana' => [
            {
              required: true,
              name: :api_key,
              type: String,
              desc: 'User API token'
            },
            {
              required: false,
              name: :restrict_to_branch,
              type: String,
              desc: 'Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches'
            }
          ],
          'assembla' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'The authentication token'
            },
            {
              required: false,
              name: :subdomain,
              type: String,
              desc: 'Subdomain setting'
            }
          ],
          'bamboo' => [
            {
              required: true,
              name: :bamboo_url,
              type: String,
              desc: 'Bamboo root URL like https://bamboo.example.com'
            },
            {
              required: false,
              name: :enable_ssl_verification,
              type: Boolean,
              desc: 'Enable SSL verification'
            },
            {
              required: true,
              name: :build_key,
              type: String,
              desc: 'Bamboo build plan key like'
            },
            {
              required: true,
              name: :username,
              type: String,
              desc: 'A user with API access, if applicable'
            },
            {
              required: true,
              name: :password,
              type: String,
              desc: 'Password of the user'
            }
          ],
          'bugzilla' => [
            {
              required: true,
              name: :new_issue_url,
              type: String,
              desc: 'New issue URL'
            },
            {
              required: true,
              name: :issues_url,
              type: String,
              desc: 'Issues URL'
            },
            {
              required: true,
              name: :project_url,
              type: String,
              desc: 'Project URL'
            }
          ],
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
              type: Boolean,
              desc: 'DEPRECATED: This parameter has no effect since SSL verification will always be enabled'
            }
          ],
          'campfire' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'Campfire token'
            },
            {
              required: false,
              name: :subdomain,
              type: String,
              desc: 'Campfire subdomain'
            },
            {
              required: false,
              name: :room,
              type: String,
              desc: 'Campfire room'
            }
          ],
          'confluence' => [
            {
              required: true,
              name: :confluence_url,
              type: String,
              desc: 'The URL of the Confluence Cloud Workspace hosted on atlassian.net'
            }
          ],
          'custom-issue-tracker' => [
            {
              required: true,
              name: :new_issue_url,
              type: String,
              desc: 'New issue URL'
            },
            {
              required: true,
              name: :issues_url,
              type: String,
              desc: 'Issues URL'
            },
            {
              required: true,
              name: :project_url,
              type: String,
              desc: 'Project URL'
            }
          ],
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
              type: Boolean,
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
          'discord' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'Discord webhook. For example, https://discord.com/api/webhooks/…'
            }
          ],
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
              type: Boolean,
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
              type: Boolean,
              desc: 'Disable code diffs'
            },
            {
              required: false,
              name: :send_from_committer_email,
              type: Boolean,
              desc: 'Send from committer'
            },
            {
              required: false,
              name: :branches_to_be_notified,
              type: String,
              desc: 'Branches for which notifications are to be sent'
            }
          ],
          'external-wiki' => [
            {
              required: true,
              name: :external_wiki_url,
              type: String,
              desc: 'The URL of the external wiki'
            }
          ],
          'google-play' => [
            {
              required: true,
              name: :package_name,
              type: String,
              desc: 'The package name of the app in Google Play'
            },
            {
              required: true,
              name: :service_account_key,
              type: String,
              desc: 'The Google Play service account key'
            },
            {
              required: true,
              name: :service_account_key_file_name,
              type: String,
              desc: 'The filename of the Google Play service account key'
            }
          ],
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
            },
            chat_notification_events
          ].flatten,
          'harbor' => [
            {
              required: true,
              name: :url,
              type: String,
              desc: 'The base URL to the Harbor instance which is being linked to this GitLab project. For example, https://demo.goharbor.io.'
            },
            {
              required: true,
              name: :project_name,
              type: String,
              desc: 'The Project name to the Harbor instance. For example, testproject.'
            },
            {
              required: true,
              name: :username,
              type: String,
              desc: 'The username created from Harbor interface.'
            },
            {
              required: true,
              name: :password,
              type: String,
              desc: 'The password of the user.'
            }
          ],
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
              type: Boolean,
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
              type: Boolean,
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
              desc: 'The authorization type for Jira'
            },
            {
              required: false,
              name: :username,
              type: String,
              desc: 'The username of the user created to be used with GitLab/Jira'
            },
            {
              required: true,
              name: :password,
              type: String,
              desc: 'The password of the user created to be used with GitLab/Jira'
            },
            {
              required: false,
              name: :jira_issue_transition_automatic,
              type: Boolean,
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
              type: Boolean,
              desc: 'Enable comments inside Jira issues on each GitLab event (commit / merge request)'
            }
          ],
          'mattermost-slash-commands' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'The Mattermost token'
            }
          ],
          'shimo' => [
            {
              required: true,
              name: :external_wiki_url,
              type: String,
              desc: 'Shimo workspace URL'
            }
          ],
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
              type: Boolean,
              desc: 'Notify only broken pipelines'
            },
            {
              required: false,
              name: :notify_only_default_branch,
              type: Boolean,
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
            },
            chat_notification_events
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
          'redmine' => [
            {
              required: true,
              name: :new_issue_url,
              type: String,
              desc: 'The new issue URL'
            },
            {
              required: true,
              name: :project_url,
              type: String,
              desc: 'The project URL'
            },
            {
              required: true,
              name: :issues_url,
              type: String,
              desc: 'The issues URL'
            }
          ],
          'ewm' => [
            {
              required: true,
              name: :new_issue_url,
              type: String,
              desc: 'New Issue URL'
            },
            {
              required: true,
              name: :project_url,
              type: String,
              desc: 'Project URL'
            },
            {
              required: true,
              name: :issues_url,
              type: String,
              desc: 'Issues URL'
            }
          ],
          'youtrack' => [
            {
              required: true,
              name: :project_url,
              type: String,
              desc: 'The project URL'
            },
            {
              required: true,
              name: :issues_url,
              type: String,
              desc: 'The issues URL'
            }
          ],
          'slack' => [
            chat_notification_settings,
            chat_notification_flags,
            chat_notification_channels,
            chat_notification_events
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
            chat_notification_settings,
            chat_notification_flags,
            chat_notification_channels,
            chat_notification_events
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
              type: Boolean,
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
          'unify-circuit' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'The Unify Circuit webhook. e.g. https://circuit.com/rest/v2/webhooks/incoming/…'
            },
            chat_notification_events
          ].flatten,
          'webex-teams' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'The Webex Teams webhook. For example, https://api.ciscospark.com/v1/webhooks/incoming/...'
            },
            chat_notification_events
          ].flatten,
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
          'squash-tm' => [
            {
              required: true,
              name: :url,
              type: String,
              desc: 'The Squash TM webhook URL'
            },
            {
              required: false,
              name: :token,
              type: String,
              desc: 'The secret token'
            }
          ]
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
          ::Integrations::Confluence,
          ::Integrations::CustomIssueTracker,
          ::Integrations::Datadog,
          ::Integrations::Discord,
          ::Integrations::DroneCi,
          ::Integrations::EmailsOnPush,
          ::Integrations::Ewm,
          ::Integrations::ExternalWiki,
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
          ::Integrations::PipelinesEmail,
          ::Integrations::Pivotaltracker,
          ::Integrations::Prometheus,
          ::Integrations::Pushover,
          ::Integrations::Redmine,
          ::Integrations::Slack,
          ::Integrations::SlackSlashCommands,
          ::Integrations::SquashTm,
          ::Integrations::Teamcity,
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
