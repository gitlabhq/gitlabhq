# frozen_string_literal: true

module API
  module Helpers
    # Helpers module for API::Services
    #
    # The data structures inside this model are returned using class methods,
    # allowing EE to extend them where necessary.
    module ServicesHelpers
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

      def self.services
        {
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
            },
            {
              required: false,
              name: :description,
              type: String,
              desc: 'Description'
            },
            {
              required: false,
              name: :title,
              type: String,
              desc: 'Title'
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
              desc: 'The buildkite project URL'
            },
            {
              required: false,
              name: :enable_ssl_verification,
              type: Boolean,
              desc: 'Enable SSL verification for communication'
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
            },
            {
              required: false,
              name: :description,
              type: String,
              desc: 'Description'
            },
            {
              required: false,
              name: :title,
              type: String,
              desc: 'Title'
            }
          ],
          'discord' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'Discord webhook. e.g. https://discordapp.com/api/webhooks/…'
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
              desc: 'Enable SSL verification for communication'
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
            }
          ],
          'external-wiki' => [
            {
              required: true,
              name: :external_wiki_url,
              type: String,
              desc: 'The URL of the external Wiki'
            }
          ],
          'flowdock' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'Flowdock token'
            }
          ],
          'hangouts-chat' => [
            {
              required: true,
              name: :webhook,
              type: String,
              desc: 'The Hangouts Chat webhook. e.g. https://chat.googleapis.com/v1/spaces…'
            },
            chat_notification_events
          ].flatten,
          'hipchat' => [
            {
              required: true,
              name: :token,
              type: String,
              desc: 'The room token'
            },
            {
              required: false,
              name: :room,
              type: String,
              desc: 'The room name or ID'
            },
            {
              required: false,
              name: :color,
              type: String,
              desc: 'The room color'
            },
            {
              required: false,
              name: :notify,
              type: Boolean,
              desc: 'Enable notifications'
            },
            {
              required: false,
              name: :api_version,
              type: String,
              desc: 'Leave blank for default (v2)'
            },
            {
              required: false,
              name: :server,
              type: String,
              desc: 'Leave blank for default. https://hipchat.example.com'
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
              required: true,
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
              name: :jira_issue_transition_id,
              type: String,
              desc: 'The ID of a transition that moves issues to a closed state. You can find this number under the Jira workflow administration (**Administration > Issues > Workflows**) by selecting **View** under **Operations** of the desired workflow of your project. The ID of each state can be found inside the parenthesis of each transition name under the **Transitions (id)** column ([see screenshot][trans]). By default, this ID is set to `2`'
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
            }
          ],
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
            },
            {
              required: false,
              name: :description,
              type: String,
              desc: 'The description of the tracker'
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
            },
            {
              required: false,
              name: :description,
              type: String,
              desc: 'The description of the tracker'
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
          ]
        }
      end

      def self.service_classes
        [
          ::AsanaService,
          ::AssemblaService,
          ::BambooService,
          ::BugzillaService,
          ::BuildkiteService,
          ::CampfireService,
          ::CustomIssueTrackerService,
          ::DiscordService,
          ::DroneCiService,
          ::EmailsOnPushService,
          ::ExternalWikiService,
          ::FlowdockService,
          ::HangoutsChatService,
          ::HipchatService,
          ::IrkerService,
          ::JiraService,
          ::MattermostSlashCommandsService,
          ::SlackSlashCommandsService,
          ::PackagistService,
          ::PipelinesEmailService,
          ::PivotaltrackerService,
          ::PrometheusService,
          ::PushoverService,
          ::RedmineService,
          ::YoutrackService,
          ::SlackService,
          ::MattermostService,
          ::MicrosoftTeamsService,
          ::TeamcityService
        ]
      end

      def self.development_service_classes
        [
          ::MockCiService,
          ::MockDeploymentService,
          ::MockMonitoringService
        ]
      end
    end
  end
end

API::Helpers::ServicesHelpers.prepend_if_ee('EE::API::Helpers::ServicesHelpers')
