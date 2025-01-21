# frozen_string_literal: true

constraints(::Constraints::ProjectUrlConstrainer.new) do
  # If the route has a wildcard segment, the segment has a regex constraint,
  # the segment is potentially followed by _another_ wildcard segment, and
  # the `format` option is not set to false, we need to specify that
  # regex constraint _outside_ of `constraints: {}`.
  #
  # Otherwise, Rails will overwrite the constraint with `/.+?/`,
  # which breaks some of our wildcard routes like `/blob/*id`
  # and `/tree/*id` that depend on the negative lookahead inside
  # `Gitlab::PathRegex.full_namespace_route_regex`, which helps the router
  # determine whether a certain path segment is part of `*namespace_id`,
  # `:project_id`, or `*id`.
  #
  # See https://github.com/rails/rails/blob/v4.2.8/actionpack/lib/action_dispatch/routing/mapper.rb#L155
  scope(
    path: '*namespace_id',
    as: :namespace,
    namespace_id: Gitlab::PathRegex.full_namespace_route_regex
  ) do
    scope(
      path: ':project_id',
      constraints: { project_id: Gitlab::PathRegex.project_route_regex },
      module: :projects,
      as: :project
    ) do
      # Begin of the /-/ scope.
      # Use this scope for all new project routes.
      scope '-' do
        post :preview_markdown

        get 'archive/*id', format: true, constraints: { format: Gitlab::PathRegex.archive_formats_regex, id: /.+?/ }, to: 'repositories#archive', as: 'archive'

        namespace :security do
          resource :configuration, only: [:show], controller: :configuration do
            resource :sast, only: [:show], controller: :sast_configuration
          end
        end

        resources :artifacts, only: [:index, :destroy]

        resources :packages, only: [:index, :show, :destroy], module: :packages
        resources :package_files, only: [], module: :packages do
          member do
            get :download
          end
        end

        resources :terraform_module_registry, only: [:index, :show], module: :packages, as: :infrastructure_registry, controller: 'infrastructure_registry'
        get :infrastructure_registry, to: redirect('%{namespace_id}/%{project_id}/-/terraform_module_registry')

        resources :jobs, only: [:index, :show], constraints: { id: /\d+/ } do
          collection do
            resources :artifacts, only: [] do
              collection do
                get :latest_succeeded,
                  path: '*ref_name_and_path',
                  format: false
              end
            end
          end

          member do
            get :status
            post :cancel
            post :unschedule
            post :retry
            post :play
            post :erase
            get :trace, defaults: { format: 'json' }
            get :raw
            get :viewer
            get :terminal
            get :proxy
            get :test_report_summary

            # These routes are also defined in gitlab-workhorse. Make sure to update accordingly.
            get '/terminal.ws/authorize', to: 'jobs#terminal_websocket_authorize', format: false
            get '/proxy.ws/authorize', to: 'jobs#proxy_websocket_authorize', format: false
          end

          resource :artifacts, only: [] do
            get :download
            get :browse, path: 'browse(/*path)', format: false
            get :file, path: 'file/*path', format: false
            get :external_file, path: 'external_file/*path', format: false
            get :raw, path: 'raw/*path', format: false
            post :keep
          end
        end

        namespace :ci do
          resource :lint, only: [:show, :create]
          resource :pipeline_editor, only: [:show], controller: :pipeline_editor, path: 'editor'
          resources :daily_build_group_report_results, only: [:index], constraints: { format: /(csv|json)/ }
          namespace :prometheus_metrics do
            resources :histograms, only: [:create], constraints: { format: 'json' }
          end
        end

        resources :runners, only: [:index, :new, :edit, :update, :destroy, :show] do
          member do
            get :register
            post :resume
            post :pause
          end

          collection do
            post :toggle_shared_runners
            post :toggle_group_runners
          end
        end

        namespace :settings do
          resource :ci_cd, only: [:show, :update], controller: 'ci_cd' do
            post :reset_cache
            put :reset_registration_token
            post :create_deploy_token, path: 'deploy_token/create', to: 'repository#create_deploy_token'
            get :runner_setup_scripts, format: :json
            get :export_job_token_authorizations, defaults: { format: :csv }
          end

          resource :operations, only: [:show, :update] do
            member do
              post :reset_alerting_token
              post :reset_pagerduty_token
            end
          end

          resources :integrations, constraints: { id: %r{[^/]+} }, only: [:index, :edit, :update] do
            member do
              put :test
            end

            resources :hook_logs, only: [:show], controller: :integration_hook_logs do
              member do
                post :retry
              end
            end
          end

          resource :slack, only: [:destroy, :edit, :update] do
            get :slack_auth
          end

          resource :repository, only: [:show, :update], controller: :repository do
            # TODO: Removed this "create_deploy_token" route after change was made in app/helpers/ci_variables_helper.rb:14
            # See MR comment for more detail: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27059#note_311585356
            post :create_deploy_token, path: 'deploy_token/create'
            post :cleanup

            resources :branch_rules, only: [:index]
          end

          resources :access_tokens, only: [:index, :create] do
            member do
              put :revoke
              put :rotate
            end

            collection do
              get :inactive, format: :json
            end
          end

          resource :packages_and_registries, only: [:show] do
            get '/cleanup_image_tags', to: 'packages_and_registries#cleanup_tags'
          end
          resource :merge_requests, only: [:show, :update]
        end

        resources :usage_quotas, only: [:index]

        resources :autocomplete_sources, only: [] do
          collection do
            get 'members'
            get 'issues'
            get 'merge_requests'
            get 'labels'
            get 'milestones'
            get 'commands'
            get 'snippets'
            get 'contacts'
            get 'wikis'
          end
        end

        resources :project_members, except: [:show, :new, :create, :edit], constraints: { id: %r{[a-zA-Z./0-9_\-#%+:]+} }, concerns: :access_requestable do
          collection do
            delete :leave
          end

          member do
            post :resend_invite
          end
        end

        resources :deploy_keys, constraints: { id: /\d+/ }, only: [:index, :new, :create, :edit, :update] do
          collection do
            get :enabled_keys
            get :available_project_keys
            get :available_public_keys
          end

          member do
            put :enable
            put :disable
          end
        end

        resources :deploy_tokens, constraints: { id: /\d+/ }, only: [] do
          member do
            put :revoke
          end
        end

        resources :milestones, constraints: { id: /\d+/ } do
          member do
            post :promote
            get :issues
            get :merge_requests
            get :participants
            get :labels
          end
        end

        resources :labels, except: [:show], constraints: { id: /\d+/ } do
          collection do
            post :generate
            post :set_priorities
          end

          member do
            post :promote
            post :toggle_subscription
            delete :remove_priority
          end
        end

        resources :boards, only: [:index, :show], constraints: { id: /\d+/ }

        get 'releases/permalink/latest(/)(*suffix_path)', to: 'releases#latest_permalink', as: :latest_release_permalink, format: false

        resources :releases, only: [:index, :new, :show, :edit], param: :tag, constraints: { tag: %r{[^\\]+} } do
          member do
            get :downloads, path: 'downloads/*filepath', format: false
            scope module: :releases do
              resources :evidences, only: [:show]
            end
          end
        end

        resources :starrers, only: [:index]
        resources :forks, only: [:index, :new, :create]
        resources :group_links, only: [:update, :destroy], constraints: { id: /\d+|:id/ }

        resource :import, only: [:new, :create, :show]
        resource :avatar, only: [:show, :destroy]

        resource :mattermost, only: [:new, :create]
        resource :variables, only: [:show, :update]
        resources :triggers, only: [:index, :create, :update, :destroy]

        resource :mirror, only: [:show, :update] do
          member do
            get :ssh_host_keys, constraints: { format: :json }
            post :update_now
          end
        end

        resource :cycle_analytics, only: :show, path: 'value_stream_analytics'
        scope module: :cycle_analytics, as: 'cycle_analytics', path: 'value_stream_analytics' do
          scope :events, controller: 'events' do
            get :issue
            get :plan
            get :code
            get :test
            get :review
            get :staging
            get :production
          end
        end
        get '/cycle_analytics', to: redirect('%{namespace_id}/%{project_id}/-/value_stream_analytics')

        namespace :analytics do
          resource :cycle_analytics, only: :show, path: 'value_stream_analytics'
          scope module: :cycle_analytics, as: 'cycle_analytics', path: 'value_stream_analytics' do
            resources :value_streams, only: [:index] do
              resources :stages, only: [:index] do
                member do
                  get :median
                  get :average
                  get :records
                  get :count
                end
              end
            end
            resource :summary, controller: :summary, only: :show
          end
        end

        resources :cluster_agents, only: [:show], param: :name

        concerns :clusterable

        resources :terraform, only: [:index]

        namespace :google_cloud do
          get '/', to: redirect('%{namespace_id}/%{project_id}/-/google_cloud/configuration')

          get '/configuration', to: 'configuration#index'

          resources :revoke_oauth, only: [:create]
          resources :service_accounts, only: [:index, :create]
          resources :gcp_regions, only: [:index, :create]

          get '/deployments', to: 'deployments#index'
          get '/deployments/cloud_run', to: 'deployments#cloud_run'
          get '/deployments/cloud_storage', to: 'deployments#cloud_storage'

          resources :databases, only: [:index, :create, :new], path_names: { new: 'new/:product' }
        end

        namespace :aws do
          get '/', to: redirect('%{namespace_id}/%{project_id}/-/aws/configuration')

          get '/configuration', to: 'configuration#index'
        end

        resources :environments, except: [:destroy] do
          member do
            post :stop
            post :cancel_auto_stop
            get :terminal
            get '/k8s(/*vueroute)', to: 'environments#k8s', as: :k8s_subroute

            # This route is also defined in gitlab-workhorse. Make sure to update accordingly.
            get '/terminal.ws/authorize', to: 'environments#terminal_websocket_authorize', format: false

            get '/prometheus/api/v1/*proxy_path', to: 'environments/prometheus_api#prometheus_proxy', as: :prometheus_api
          end

          collection do
            get :folder, path: 'folders/*id', constraints: { format: /(html|json)/ }
            get :search
          end

          resources :deployments, only: [:index, :show] do
            member do
              get :metrics
              get :additional_metrics
            end
          end
        end

        resources :alert_management, only: [:index] do
          member do
            get 'details(/*page)', to: 'alert_management#details', as: 'details'
          end
        end

        get 'alert_management/:id', to: 'alert_management#details', as: 'alert_management_alert'

        resources :work_items, only: [:show], param: :iid do
          collection do
            post :import_csv
            post 'import_csv/authorize', to: 'work_items#authorize'
          end

          member do
            get '/designs(/*vueroute)', to: 'work_items#show', as: :designs, format: false
          end
        end

        post 'incidents/integrations/pagerduty', to: 'incident_management/pager_duty_incidents#create'

        resources :incidents, only: [:index]

        namespace :incident_management do
          resources :timeline_events, only: [] do
            collection do
              post :preview_markdown
            end
          end
        end

        namespace :error_tracking do
          resources :projects, only: :index
        end

        resources :error_tracking, only: [:index], controller: :error_tracking do
          collection do
            get ':issue_id/details',
              to: 'error_tracking#details',
              as: 'details'
            get ':issue_id/stack_trace',
              to: 'error_tracking/stack_traces#index',
              as: 'stack_trace'
            put ':issue_id',
              to: 'error_tracking#update',
              as: 'update'
          end
        end

        namespace :design_management do
          namespace :designs, path: 'designs/:design_id(/:sha)', constraints: ->(params) { params[:sha].nil? || Gitlab::Git.commit_id?(params[:sha]) } do
            resource :raw_image, only: :show
            resources :resized_image, only: :show, constraints: ->(params) { ::DesignManagement::DESIGN_IMAGE_SIZES.include?(params[:id]) }
          end
        end

        get '/snippets/:snippet_id/raw/:ref/*path',
          to: 'snippets/blobs#raw',
          format: false,
          as: :snippet_blob_raw,
          constraints: { snippet_id: /\d+/ }

        draw :issues
        draw :merge_requests
        draw :pipelines

        # The wiki and repository routing contains wildcard characters so
        # its preferable to keep it below all other project routes
        draw :repository
        draw :wiki

        namespace :import do
          resource :jira, only: [:show], controller: :jira
        end

        resources :snippets, except: [:create, :update, :destroy], concerns: :awardable, constraints: { id: /\d+/ } do
          member do
            get :raw
            post :mark_as_spam
          end
        end

        resources :feature_flags, param: :iid
        resource :feature_flags_client, only: [] do
          post :reset_token
        end
        resources :feature_flags_user_lists, param: :iid, only: [:index, :new, :edit, :show]

        get '/schema/:branch/*filename',
          to: 'web_ide_schemas#show',
          format: false,
          as: :schema

        resources :hooks, only: [:index, :create, :edit, :update, :destroy], constraints: { id: /\d+/ } do
          member do
            post :test
          end

          resources :hook_logs, only: [:show] do
            member do
              post :retry
            end
          end
        end

        namespace :integrations do
          resource :slash_commands, only: [:show] do
            post :confirm
          end
        end

        resources :badges, only: [] do
          collection do
            constraints format: /svg/ do
              get :release
            end
          end
        end

        namespace :harbor do
          resources :repositories, only: [:index, :show], constraints: { id: %r{[a-zA-Z./:0-9_\-]+} } do
            resources :artifacts, only: [:index] do
              resources :tags, only: [:index]
            end
          end
        end

        namespace :ml do
          resources :experiments, only: [:index, :show, :destroy], controller: 'experiments', param: :iid
          resources :candidates, only: [:show, :destroy], controller: 'candidates', param: :iid do
            member do
              get :promote
            end
          end
          resources :models, only: [:index, :show, :edit, :destroy, :new], controller: 'models', param: :model_id do
            resources :versions, only: [:new], controller: 'model_versions'
            resources :versions, only: [:show, :edit], controller: 'model_versions', param: :model_version_id
          end
          post :preview_markdown
        end

        namespace :service_desk do
          resource :custom_email, only: [:show, :create, :update, :destroy], controller: 'custom_email'
        end

        scope path: ':noteable_type/:noteable_id' do
          resources :discussions, only: [:show], constraints: { id: /\h{40}/ } do
            member do
              post :resolve
              delete :resolve, action: :unresolve
            end
          end
        end
      end
      # End of the /-/ scope.

      # All new routes should go under /-/ scope.
      # Look for scope '-' at the top of the file.

      #
      # Service Desk
      #
      get '/service_desk' => 'service_desk#show' # rubocop:todo Cop/PutProjectRoutesUnderScope
      put '/service_desk' => 'service_desk#update' # rubocop:todo Cop/PutProjectRoutesUnderScope

      #
      # Templates
      #
      get '/templates/:template_type' => 'templates#index', # rubocop:todo Cop/PutProjectRoutesUnderScope
        as: :templates,
        defaults: { format: 'json' },
        constraints: { template_type: %r{issue|merge_request}, format: 'json' }

      get '/templates/:template_type/:key' => 'templates#show', # rubocop:todo Cop/PutProjectRoutesUnderScope
        as: :template,
        defaults: { format: 'json' },
        constraints: { key: %r{[^/]+}, template_type: %r{issue|merge_request}, format: 'json' }

      get '/description_templates/names/:template_type', # rubocop:todo Cop/PutProjectRoutesUnderScope
        to: 'templates#names',
        as: :template_names,
        defaults: { format: 'json' },
        constraints: { template_type: %r{issue|merge_request}, format: 'json' }

      resource :pages, only: [:new, :show, :update, :destroy, :regenerate_unique_domain] do # rubocop: disable Cop/PutProjectRoutesUnderScope
        post :regenerate_unique_domain # rubocop:todo Cop/PutProjectRoutesUnderScope
        resources :domains, except: :index, controller: 'pages_domains', constraints: { id: %r{[^/]+} } do # rubocop: disable Cop/PutProjectRoutesUnderScope
          member do
            post :verify # rubocop:todo Cop/PutProjectRoutesUnderScope
            post :retry_auto_ssl # rubocop:todo Cop/PutProjectRoutesUnderScope
            delete :clean_certificate # rubocop:todo Cop/PutProjectRoutesUnderScope
          end
        end
      end

      namespace :prometheus do
        resources :metrics, constraints: { id: %r{[^\/]+} }, only: [:index, :new, :create, :edit, :update, :destroy] do # rubocop: disable Cop/PutProjectRoutesUnderScope
          get :active_common, on: :collection # rubocop:todo Cop/PutProjectRoutesUnderScope
          post :validate_query, on: :collection # rubocop:todo Cop/PutProjectRoutesUnderScope
        end
      end

      scope :prometheus, as: :prometheus do
        resources :alerts, constraints: { id: /\d+/ }, only: [] do # rubocop: disable Cop/PutProjectRoutesUnderScope
          post :notify, on: :collection, to: 'alerting/notifications#create', defaults: { endpoint_identifier: 'legacy-prometheus' } # rubocop: disable Cop/PutProjectRoutesUnderScope
          get :metrics_dashboard, on: :member # rubocop:todo Cop/PutProjectRoutesUnderScope
        end
      end

      post 'alerts/notify', to: 'alerting/notifications#create', defaults: { endpoint_identifier: 'legacy' } # rubocop:todo Cop/PutProjectRoutesUnderScope
      post 'alerts/notify/:name/:endpoint_identifier', # rubocop:todo Cop/PutProjectRoutesUnderScope
        to: 'alerting/notifications#create',
        as: :alert_http_integration,
        constraints: { endpoint_identifier: /[A-Za-z0-9]+/ }

      draw :legacy_builds

      resources :container_registry, only: [:index, :destroy, :show], # rubocop: disable Cop/PutProjectRoutesUnderScope
        controller: 'registry/repositories'

      namespace :registry do
        resources :repository, only: [] do # rubocop: disable Cop/PutProjectRoutesUnderScope
          # We default to JSON format in the controller to avoid ambiguity.
          # `latest.json` could either be a request for a tag named `latest`
          # in JSON format, or a request for tag named `latest.json`.
          scope format: false do
            resources :tags, only: [:index, :destroy], # rubocop: disable Cop/PutProjectRoutesUnderScope
              constraints: { id: Gitlab::Regex.container_registry_tag_regex } do
              collection do
                delete :bulk_destroy # rubocop:todo Cop/PutProjectRoutesUnderScope
              end
            end
          end
        end
      end

      resources :notes, only: [:create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ } do # rubocop: disable Cop/PutProjectRoutesUnderScope
        member do
          delete :delete_attachment # rubocop:todo Cop/PutProjectRoutesUnderScope
          post :resolve # rubocop:todo Cop/PutProjectRoutesUnderScope
          delete :resolve, action: :unresolve # rubocop:todo Cop/PutProjectRoutesUnderScope
          get :outdated_line_change # rubocop:todo Cop/PutProjectRoutesUnderScope
        end
      end

      get 'noteable/:target_type/:target_id/notes' => 'notes#index', as: 'noteable_notes' # rubocop:todo Cop/PutProjectRoutesUnderScope

      resources :todos, only: [:create] # rubocop: disable Cop/PutProjectRoutesUnderScope

      resources :uploads, only: [:create] do # rubocop: disable Cop/PutProjectRoutesUnderScope
        collection do
          get ":secret/:filename", action: :show, as: :show, constraints: { filename: %r{[^/]+} }, format: false, defaults: { format: nil } # rubocop:todo Cop/PutProjectRoutesUnderScope
          post :authorize # rubocop:todo Cop/PutProjectRoutesUnderScope
        end
      end

      resources :runner_projects, only: [:create, :destroy] # rubocop: disable Cop/PutProjectRoutesUnderScope
      resources :badges, only: [:index] do # rubocop: disable Cop/PutProjectRoutesUnderScope
        collection do
          scope '*ref', constraints: { ref: Gitlab::PathRegex.git_reference_regex } do
            constraints format: /svg/ do
              get :pipeline # rubocop:todo Cop/PutProjectRoutesUnderScope
              get :coverage # rubocop:todo Cop/PutProjectRoutesUnderScope
            end
          end
        end
      end

      resources :web_ide_terminals, path: :ide_terminals, only: [:create, :show], constraints: { id: /\d+/, format: :json } do # rubocop: disable Cop/PutProjectRoutesUnderScope
        member do
          post :cancel # rubocop:todo Cop/PutProjectRoutesUnderScope
          post :retry # rubocop:todo Cop/PutProjectRoutesUnderScope
        end

        collection do
          post :check_config # rubocop:todo Cop/PutProjectRoutesUnderScope
        end
      end

      # Deprecated unscoped routing.
      scope as: 'deprecated' do
        # Issue https://gitlab.com/gitlab-org/gitlab/issues/118849
        draw :repository_deprecated

        # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/223719
        # rubocop: disable Cop/PutProjectRoutesUnderScope
        get '/snippets/:id/raw',
          to: 'snippets#raw',
          format: false,
          constraints: { id: /\d+/ }
        # rubocop: enable Cop/PutProjectRoutesUnderScope
      end

      # All new routes should go under /-/ scope.
      # Look for scope '-' at the top of the file.

      # Legacy routes.
      # Introduced in 12.0.
      # Should be removed with https://gitlab.com/gitlab-org/gitlab/issues/28848.
      Gitlab::Routing.redirect_legacy_paths(
        self, :mirror, :tags, :hooks,
        :commits, :commit, :find_file, :files, :compare,
        :cycle_analytics, :mattermost, :variables, :triggers,
        :environments, :protected_environments, :error_tracking, :alert_management,
        :serverless, :clusters, :audit_events, :wikis, :merge_requests,
        :vulnerability_feedback, :security, :dependencies, :issues,
        :pipelines, :pipeline_schedules, :runners, :snippets
      )
    end
    # rubocop: disable Cop/PutProjectRoutesUnderScope
    resources(
      :projects,
      path: '/',
      constraints: { id: Gitlab::PathRegex.project_route_regex },
      only: [:edit, :show, :update, :destroy]
    ) do
      member do
        put :transfer
        delete :remove_fork
        post :archive
        post :unarchive
        post :housekeeping
        post :toggle_star
        post :export
        post :remove_export
        post :generate_new_export
        get :download_export
        get :activity
        get :refs
        put :new_issuable_address
        get :unfoldered_environment_names
      end
    end
    # rubocop: enable Cop/PutProjectRoutesUnderScope
  end
end

# It's under /-/jira scope but cop is only checking /-/
# rubocop: disable Cop/PutProjectRoutesUnderScope
scope path: '(/-/jira)', constraints: ::Constraints::JiraEncodedUrlConstrainer.new, as: :jira do
  scope path: '*namespace_id/:project_id',
    namespace_id: Gitlab::Jira::Dvcs::ENCODED_ROUTE_REGEX,
    project_id: Gitlab::Jira::Dvcs::ENCODED_ROUTE_REGEX do
    get '/', to: redirect { |params, req|
      ::Gitlab::Jira::Dvcs.restore_full_path(
        namespace: params[:namespace_id],
        project: params[:project_id]
      )
    }

    get 'commit/:id', constraints: { id: Gitlab::Git::Commit::SHA_PATTERN }, to: redirect { |params, req|
      project_full_path = ::Gitlab::Jira::Dvcs.restore_full_path(
        namespace: params[:namespace_id],
        project: params[:project_id]
      )

      "/#{project_full_path}/commit/#{params[:id]}"
    }

    get 'tree/*id', as: nil, to: redirect { |params, req|
      project_full_path = ::Gitlab::Jira::Dvcs.restore_full_path(
        namespace: params[:namespace_id],
        project: params[:project_id]
      )

      "/#{project_full_path}/-/tree/#{params[:id]}"
    }
  end
end
# rubocop: enable Cop/PutProjectRoutesUnderScope
