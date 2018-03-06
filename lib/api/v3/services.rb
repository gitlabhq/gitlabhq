module API
  module V3
    class Services < Grape::API
      services = {
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
        'builds-email' => [
          {
            required: true,
            name: :recipients,
            type: String,
            desc: 'Comma-separated list of recipient email addresses'
          },
          {
            required: false,
            name: :add_pusher,
            type: Boolean,
            desc: 'Add pusher to recipients list'
          },
          {
            required: false,
            name: :notify_only_broken_builds,
            type: Boolean,
            desc: 'Notify only broken builds'
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
        'gemnasium' => [
          {
            required: true,
            name: :api_key,
            type: String,
            desc: 'Your personal API key on gemnasium.com'
          },
          {
            required: true,
            name: :token,
            type: String,
            desc: "The project's slug on gemnasium.com"
          }
        ],
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
            desc: 'The URL to the JIRA project which is being linked to this GitLab project, e.g., https://jira.example.com'
          },
          {
            required: true,
            name: :project_key,
            type: String,
            desc: 'The short identifier for your JIRA project, all uppercase, e.g., PROJ'
          },
          {
            required: false,
            name: :username,
            type: String,
            desc: 'The username of the user created to be used with GitLab/JIRA'
          },
          {
            required: false,
            name: :password,
            type: String,
            desc: 'The password of the user created to be used with GitLab/JIRA'
          },
          {
            required: false,
            name: :jira_issue_transition_id,
            type: Integer,
            desc: 'The ID of a transition that moves issues to a closed state. You can find this number under the JIRA workflow administration (**Administration > Issues > Workflows**) by selecting **View** under **Operations** of the desired workflow of your project. The ID of each state can be found inside the parenthesis of each transition name under the **Transitions (id)** column ([see screenshot][trans]). By default, this ID is set to `2`'
          }
        ],
        'kubernetes' => [
          {
            required: true,
            name: :namespace,
            type: String,
            desc: 'The Kubernetes namespace to use'
          },
          {
            required: true,
            name: :api_url,
            type: String,
            desc: 'The URL to the Kubernetes cluster API, e.g., https://kubernetes.example.com'
          },
          {
            required: true,
            name: :token,
            type: String,
            desc: 'The service token to authenticate against the Kubernetes cluster with'
          },
          {
            required: false,
            name: :ca_pem,
            type: String,
            desc: 'A custom certificate authority bundle to verify the Kubernetes cluster with (PEM format)'
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
            name: :notify_only_broken_builds,
            type: Boolean,
            desc: 'Notify only broken builds'
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
        'slack' => [
          {
            required: true,
            name: :webhook,
            type: String,
            desc: 'The Slack webhook. e.g. https://hooks.slack.com/services/...'
          },
          {
            required: false,
            name: :new_issue_url,
            type: String,
            desc: 'The user name'
          },
          {
            required: false,
            name: :channel,
            type: String,
            desc: 'The channel name'
          }
        ],
        'microsoft-teams' => [
          required: true,
          name: :webhook,
          type: String,
          desc: 'The Microsoft Teams webhook. e.g. https://outlook.office.com/webhook/…'
        ],
        'mattermost' => [
          {
            required: true,
            name: :webhook,
            type: String,
            desc: 'The Mattermost webhook. e.g. http://mattermost_host/hooks/...'
          }
        ],
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
        ],
        # EE-specific services
        'github' => [
          {
            required: true,
            name: :token,
            type: String,
            desc: 'GitHub API token with repo:status OAuth scope'
          },
          {
            required: true,
            name: :repository_name,
            type: String,
            desc: "GitHub repository URL"
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
        'jenkins-deprecated' => [
          {
            required: true,
            name: :project_url,
            type: String,
            desc: 'Jenkins project URL like http://jenkins.example.com/job/my-project/'
          },
          {
            required: false,
            name: :pass_unstable,
            type: Boolean,
            desc: 'Multi-project setup enabled?'
          },
          {
            required: false,
            name: :multiproject_enabled,
            type: Boolean,
            desc: 'Should unstable builds be treated as passing?'
          }
        ]
      }

      trigger_services = {
        'mattermost-slash-commands' => [
          {
            name: :token,
            type: String,
            desc: 'The Mattermost token'
          }
        ],
        'slack-slash-commands' => [
          {
            name: :token,
            type: String,
            desc: 'The Slack token'
          }
        ]
      }.freeze

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        before { authenticate! }
        before { authorize_admin_project }

        helpers do
          def service_attributes(service)
            service.fields.inject([]) do |arr, hash|
              arr << hash[:name].to_sym
            end
          end
        end

        desc "Delete a service for project"
        params do
          requires :service_slug, type: String, values: services.keys, desc: 'The name of the service'
        end
        delete ":id/services/:service_slug" do
          service = user_project.find_or_initialize_service(params[:service_slug].underscore)

          attrs = service_attributes(service).inject({}) do |hash, key|
            hash.merge!(key => nil)
          end

          if service.update_attributes(attrs.merge(active: false))
            status(200)
            true
          else
            render_api_error!('400 Bad Request', 400)
          end
        end

        desc 'Get the service settings for project' do
          success Entities::ProjectService
        end
        params do
          requires :service_slug, type: String, values: services.keys, desc: 'The name of the service'
        end
        get ":id/services/:service_slug" do
          service = user_project.find_or_initialize_service(params[:service_slug].underscore)
          present service, with: Entities::ProjectService
        end
      end

      trigger_services.each do |service_slug, settings|
        helpers do
          def slash_command_service(project, service_slug, params)
            project.services.active.where(template: false).find do |service|
              service.try(:token) == params[:token] && service.to_param == service_slug.underscore
            end
          end
        end

        params do
          requires :id, type: String, desc: 'The ID of a project'
        end
        resource :projects, requirements: { id: %r{[^/]+} } do
          desc "Trigger a slash command for #{service_slug}" do
            detail 'Added in GitLab 8.13'
          end
          params do
            settings.each do |setting|
              requires setting[:name], type: setting[:type], desc: setting[:desc]
            end
          end
          post ":id/services/#{service_slug.underscore}/trigger" do
            project = find_project(params[:id])

            # This is not accurate, but done to prevent leakage of the project names
            not_found!('Service') unless project

            service = slash_command_service(project, service_slug, params)
            result = service.try(:trigger, params)

            if result
              status result[:status] || 200
              present result
            else
              not_found!('Service')
            end
          end
        end
      end
    end
  end
end
