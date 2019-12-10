# frozen_string_literal: true

# rubocop: disable Cop/PutProjectRoutesUnderScope
resources :projects, only: [:index, :new, :create]

draw :git_http

get '/projects/:id' => 'projects#resolve'
# rubocop: enable Cop/PutProjectRoutesUnderScope

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
  scope(path: '*namespace_id',
        as: :namespace,
        namespace_id: Gitlab::PathRegex.full_namespace_route_regex) do
    scope(path: ':project_id',
          constraints: { project_id: Gitlab::PathRegex.project_route_regex },
          module: :projects,
          as: :project) do

      # Begin of the /-/ scope.
      # Use this scope for all new project routes.
      scope '-' do
        get 'archive/*id', constraints: { format: Gitlab::PathRegex.archive_formats_regex, id: /.+?/ }, to: 'repositories#archive', as: 'archive'

        resources :artifacts, only: [:index, :destroy]

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
            get :terminal
            get '/terminal.ws/authorize', to: 'jobs#terminal_websocket_authorize', format: false
          end

          resource :artifacts, only: [] do
            get :download
            get :browse, path: 'browse(/*path)', format: false
            get :file, path: 'file/*path', format: false
            get :raw, path: 'raw/*path', format: false
            post :keep
          end
        end

        namespace :ci do
          resource :lint, only: [:show, :create]
        end

        namespace :settings do
          get :members, to: redirect("%{namespace_id}/%{project_id}/project_members")

          resource :ci_cd, only: [:show, :update], controller: 'ci_cd' do
            post :reset_cache
            put :reset_registration_token
          end

          resource :operations, only: [:show, :update]
          resource :integrations, only: [:show]

          resource :repository, only: [:show], controller: :repository do
            post :create_deploy_token, path: 'deploy_token/create'
            post :cleanup
          end
        end

        resources :autocomplete_sources, only: [] do
          collection do
            get 'members'
            get 'issues'
            get 'merge_requests'
            get 'labels'
            get 'milestones'
            get 'commands'
            get 'snippets'
          end
        end

        resources :project_members, except: [:show, :new, :edit], constraints: { id: %r{[a-zA-Z./0-9_\-#%+]+} }, concerns: :access_requestable do
          collection do
            delete :leave

            # Used for import team
            # from another project
            get :import
            post :apply_import
          end

          member do
            post :resend_invite
          end
        end

        resources :deploy_keys, constraints: { id: /\d+/ }, only: [:index, :new, :create, :edit, :update] do
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
            put :sort_issues
            put :sort_merge_requests
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

        resources :services, constraints: { id: %r{[^/]+} }, only: [:edit, :update] do
          member do
            put :test
          end
        end

        resources :boards, only: [:index, :show, :create, :update, :destroy], constraints: { id: /\d+/ } do
          collection do
            get :recent
          end
        end

        resources :releases, only: [:index, :edit], param: :tag, constraints: { tag: %r{[^/]+} } do
          member do
            get :evidence
          end
        end

        resources :starrers, only: [:index]
        resources :forks, only: [:index, :new, :create]
        resources :group_links, only: [:index, :create, :update, :destroy], constraints: { id: /\d+/ }

        resource :import, only: [:new, :create, :show]
        resource :avatar, only: [:show, :destroy]

        scope :grafana, as: :grafana_api do
          get 'proxy/:datasource_id/*proxy_path', to: 'grafana_api#proxy'
          get :metrics_dashboard, to: 'grafana_api#metrics_dashboard'
        end

        resource :mattermost, only: [:new, :create]
        resource :variables, only: [:show, :update]
        resources :triggers, only: [:index, :create, :edit, :update, :destroy]

        resource :mirror, only: [:show, :update] do
          member do
            get :ssh_host_keys, constraints: { format: :json }
            post :update_now
          end
        end

        resource :cycle_analytics, only: [:show]

        namespace :cycle_analytics do
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

        concerns :clusterable

        namespace :serverless do
          scope :functions do
            get '/:environment_id/:id', to: 'functions#show'
            get '/:environment_id/:id/metrics', to: 'functions#metrics', as: :metrics
          end

          resources :functions, only: [:index]
        end

        resources :environments, except: [:destroy] do
          member do
            post :stop
            post :cancel_auto_stop
            get :terminal
            get :metrics
            get :additional_metrics
            get :metrics_dashboard
            get '/terminal.ws/authorize', to: 'environments#terminal_websocket_authorize', format: false

            get '/prometheus/api/v1/*proxy_path', to: 'environments/prometheus_api#proxy', as: :prometheus_api
          end

          collection do
            get :metrics, action: :metrics_redirect
            get :folder, path: 'folders/*id', constraints: { format: /(html|json)/ }
            get :search
          end

          resources :deployments, only: [:index] do
            member do
              get :metrics
              get :additional_metrics
            end
          end
        end

        resources :error_tracking, only: [:index], controller: :error_tracking do
          collection do
            get ':issue_id/details',
              to: 'error_tracking#details',
              as: 'details'
            get ':issue_id/stack_trace',
              to: 'error_tracking#stack_trace',
              as: 'stack_trace'
            post :list_projects
          end
        end

        # The wiki routing contains wildcard characters so
        # its preferable to keep it below all other project routes
        draw :wiki
      end
      # End of the /-/ scope.

      # All new routes should go under /-/ scope.
      # Look for scope '-' at the top of the file.
      # rubocop: disable Cop/PutProjectRoutesUnderScope

      #
      # Templates
      #
      get '/templates/:template_type/:key' => 'templates#show',
          as: :template,
          defaults: { format: 'json' },
          constraints: { key: %r{[^/]+}, template_type: %r{issue|merge_request}, format: 'json' }

      get '/description_templates/names/:template_type',
          to: 'templates#names',
          as: :template_names,
          defaults: { format: 'json' },
          constraints: { template_type: %r{issue|merge_request}, format: 'json' }

      resources :commit, only: [:show], constraints: { id: /\h{7,40}/ } do
        member do
          get :branches
          get :pipelines
          post :revert
          post :cherry_pick
          get :diff_for_path
          get :merge_requests
        end
      end

      resource :pages, only: [:show, :update, :destroy] do
        resources :domains, except: :index, controller: 'pages_domains', constraints: { id: %r{[^/]+} } do
          member do
            post :verify
            delete :clean_certificate
          end
        end
      end

      resources :snippets, concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          get :raw
          post :mark_as_spam
        end
      end

      namespace :prometheus do
        resources :metrics, constraints: { id: %r{[^\/]+} }, only: [:index, :new, :create, :edit, :update, :destroy] do
          get :active_common, on: :collection
        end
      end

      resources :merge_requests, concerns: :awardable, except: [:new, :create, :show], constraints: { id: /\d+/ } do
        member do
          get :show # Insert this first to ensure redirections using merge_requests#show match this route
          get :commit_change_content
          post :merge
          post :cancel_auto_merge
          get :pipeline_status
          get :ci_environments_status
          post :toggle_subscription
          post :remove_wip
          post :assign_related_issues
          get :discussions, format: :json
          post :rebase
          get :test_reports
          get :exposed_artifacts

          scope constraints: ->(req) { req.format == :json }, as: :json do
            get :commits
            get :pipelines
            get :diffs, to: 'merge_requests/diffs#show'
            get :diffs_batch, to: 'merge_requests/diffs#diffs_batch'
            get :diffs_metadata, to: 'merge_requests/diffs#diffs_metadata'
            get :widget, to: 'merge_requests/content#widget'
            get :cached_widget, to: 'merge_requests/content#cached_widget'
          end

          scope action: :show do
            get :commits, defaults: { tab: 'commits' }
            get :pipelines, defaults: { tab: 'pipelines' }
            get :diffs, defaults: { tab: 'diffs' }
          end

          get :diff_for_path, controller: 'merge_requests/diffs'

          scope controller: 'merge_requests/conflicts' do
            get :conflicts, action: :show
            get :conflict_for_path
            post :resolve_conflicts
          end
        end

        collection do
          get :diff_for_path
          post :bulk_update
        end

        resources :discussions, only: [:show], constraints: { id: /\h{40}/ } do
          member do
            post :resolve
            delete :resolve, action: :unresolve
          end
        end
      end

      scope path: 'merge_requests', controller: 'merge_requests/creations' do
        post '', action: :create, as: nil

        scope path: 'new', as: :new_merge_request do
          get '', action: :new

          scope constraints: ->(req) { req.format == :json }, as: :json do
            get :diffs
            get :pipelines
          end

          scope action: :new do
            get :diffs, defaults: { tab: 'diffs' }
            get :pipelines, defaults: { tab: 'pipelines' }
          end

          get :diff_for_path
          get :branch_from
          get :branch_to
        end
      end

      resources :pipelines, only: [:index, :new, :create, :show] do
        collection do
          resource :pipelines_settings, path: 'settings', only: [:show, :update]
          get :charts
          scope '(*ref)', constraints: { ref: Gitlab::PathRegex.git_reference_regex } do
            get :latest, action: :show, defaults: { latest: true }
          end
        end

        member do
          get :stage
          get :stage_ajax
          post :cancel
          post :retry
          get :builds
          get :failures
          get :status
          get :test_report
        end

        member do
          resources :stages, only: [], param: :name do
            post :play_manual
          end
        end
      end

      resources :pipeline_schedules, except: [:show] do
        member do
          post :play
          post :take_ownership
        end
      end

      draw :legacy_builds

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

      resources :container_registry, only: [:index, :destroy],
                                     controller: 'registry/repositories'

      namespace :registry do
        resources :repository, only: [] do
          # We default to JSON format in the controller to avoid ambiguity.
          # `latest.json` could either be a request for a tag named `latest`
          # in JSON format, or a request for tag named `latest.json`.
          scope format: false do
            resources :tags, only: [:index, :destroy],
                             constraints: { id: Gitlab::Regex.container_registry_tag_regex } do
              collection do
                delete :bulk_destroy
              end
            end
          end
        end
      end

      get :issues, to: 'issues#calendar', constraints: lambda { |req| req.format == :ics }

      resources :issues, concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          post :toggle_subscription
          post :mark_as_spam
          post :move
          put :reorder
          get :related_branches
          get :can_create_branch
          get :realtime_changes
          post :create_merge_request
          get :discussions, format: :json
        end

        collection do
          post :bulk_update
          post :import_csv
        end
      end

      resources :notes, only: [:create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          delete :delete_attachment
          post :resolve
          delete :resolve, action: :unresolve
        end
      end

      get 'noteable/:target_type/:target_id/notes' => 'notes#index', as: 'noteable_notes'

      resources :todos, only: [:create]

      resources :uploads, only: [:create] do
        collection do
          get ":secret/:filename", action: :show, as: :show, constraints: { filename: %r{[^/]+} }
          post :authorize
        end
      end

      resources :runners, only: [:index, :edit, :update, :destroy, :show] do
        member do
          post :resume
          post :pause
        end

        collection do
          post :toggle_shared_runners
          post :toggle_group_runners
        end
      end

      resources :runner_projects, only: [:create, :destroy]
      resources :badges, only: [:index] do
        collection do
          scope '*ref', constraints: { ref: Gitlab::PathRegex.git_reference_regex } do
            constraints format: /svg/ do
              get :pipeline
              get :coverage
            end
          end
        end
      end

      scope :usage_ping, controller: :usage_ping do
        post :web_ide_clientside_preview
      end

      # The repository routing contains wildcard characters so
      # its preferable to keep it below all other project routes
      draw :repository

      # All new routes should go under /-/ scope.
      # Look for scope '-' at the top of the file.
      # rubocop: enable Cop/PutProjectRoutesUnderScope

      # Legacy routes.
      # Introduced in 12.0.
      # Should be removed with https://gitlab.com/gitlab-org/gitlab/issues/28848.
      Gitlab::Routing.redirect_legacy_paths(self, :settings, :branches, :tags,
                                            :network, :graphs, :autocomplete_sources,
                                            :project_members, :deploy_keys, :deploy_tokens,
                                            :labels, :milestones, :services, :boards, :releases,
                                            :forks, :group_links, :import, :avatar, :mirror,
                                            :cycle_analytics, :mattermost, :variables, :triggers,
                                            :environments, :protected_environments, :error_tracking,
                                            :serverless, :clusters, :audit_events, :wikis)
    end

    # rubocop: disable Cop/PutProjectRoutesUnderScope
    resources(:projects,
              path: '/',
              constraints: { id: Gitlab::PathRegex.project_route_regex },
              only: [:edit, :show, :update, :destroy]) do
      member do
        put :transfer
        delete :remove_fork
        post :archive
        post :unarchive
        post :housekeeping
        post :toggle_star
        post :preview_markdown
        post :export
        post :remove_export
        post :generate_new_export
        get :download_export
        get :activity
        get :refs
        put :new_issuable_address
      end
    end
    # rubocop: enable Cop/PutProjectRoutesUnderScope
  end
end
