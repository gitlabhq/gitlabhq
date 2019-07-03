resources :projects, only: [:index, :new, :create]

draw :git_http

get '/projects/:id' => 'projects#resolve'

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
            get '/terminal.ws/authorize', to: 'jobs#terminal_websocket_authorize', constraints: { format: nil }
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

          Gitlab.ee do
            resource :slack, only: [:destroy, :edit, :update] do
              get :slack_auth
            end
          end

          resource :repository, only: [:show], controller: :repository do
            post :create_deploy_token, path: 'deploy_token/create'
            post :cleanup
          end
        end

        Gitlab.ee do
          resources :feature_flags
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
        resources :releases, only: [:index]
        resources :forks, only: [:index, :new, :create]
        resources :group_links, only: [:index, :create, :update, :destroy], constraints: { id: /\d+/ }

        resource :import, only: [:new, :create, :show]
        resource :avatar, only: [:show, :destroy]
      end
      # End of the /-/ scope.

      #
      # Templates
      #
      get '/templates/:template_type/:key' => 'templates#show',
          as: :template,
          defaults: { format: 'json' },
          constraints: { key: %r{[^/]+}, template_type: %r{issue|merge_request}, format: 'json' }

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
          end
        end
      end

      resources :snippets, concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          get :raw
          post :mark_as_spam
        end
      end

      resource :mattermost, only: [:new, :create]

      namespace :prometheus do
        resources :metrics, constraints: { id: %r{[^\/]+} }, only: [:index, :new, :create, :edit, :update, :destroy] do
          get :active_common, on: :collection

          Gitlab.ee do
            post :validate_query, on: :collection
          end
        end

        Gitlab.ee do
          resources :alerts, constraints: { id: /\d+/ }, only: [:index, :create, :show, :update, :destroy] do
            post :notify, on: :collection
          end
        end
      end

      resources :merge_requests, concerns: :awardable, except: [:new, :create], constraints: { id: /\d+/ } do
        member do
          get :commit_change_content
          post :merge
          post :cancel_auto_merge
          get :pipeline_status
          get :ci_environments_status
          post :toggle_subscription

          Gitlab.ee do
            get :approvals
            post :approvals, action: :approve
            delete :approvals, action: :unapprove

            post :rebase
          end

          post :remove_wip
          post :assign_related_issues
          get :discussions, format: :json
          post :rebase
          get :test_reports

          scope constraints: { format: nil }, action: :show do
            get :commits, defaults: { tab: 'commits' }
            get :pipelines, defaults: { tab: 'pipelines' }
            get :diffs, defaults: { tab: 'diffs' }
          end

          scope constraints: { format: 'json' }, as: :json do
            get :commits
            get :pipelines
            get :diffs, to: 'merge_requests/diffs#show'
            get :widget, to: 'merge_requests/content#widget'
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

        Gitlab.ee do
          resources :approvers, only: :destroy
          delete 'approvers', to: 'approvers#destroy_via_user_id', as: :approver_via_user_id
          resources :approver_groups, only: :destroy

          scope module: :merge_requests do
            resources :drafts, only: [:index, :update, :create, :destroy] do
              collection do
                post :publish
                delete :discard
              end
            end
          end
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

          scope constraints: { format: nil }, action: :new do
            get :diffs, defaults: { tab: 'diffs' }
            get :pipelines, defaults: { tab: 'pipelines' }
          end

          scope constraints: { format: 'json' }, as: :json do
            get :diffs
            get :pipelines
          end

          get :diff_for_path
          get :branch_from
          get :branch_to
        end
      end

      Gitlab.ee do
        resources :path_locks, only: [:index, :destroy] do
          collection do
            post :toggle
          end
        end

        get '/service_desk' => 'service_desk#show', as: :service_desk
        put '/service_desk' => 'service_desk#update', as: :service_desk_refresh
      end

      resource :variables, only: [:show, :update]

      resources :triggers, only: [:index, :create, :edit, :update, :destroy] do
        member do
          post :take_ownership
        end
      end

      resource :mirror, only: [:show, :update] do
        member do
          get :ssh_host_keys, constraints: { format: :json }
          post :update_now
        end
      end

      Gitlab.ee do
        resources :push_rules, constraints: { id: /\d+/ }, only: [:update]
      end

      resources :pipelines, only: [:index, :new, :create, :show] do
        collection do
          resource :pipelines_settings, path: 'settings', only: [:show, :update]
          get :charts
        end

        member do
          get :stage
          get :stage_ajax
          post :cancel
          post :retry
          get :builds
          get :failures
          get :status

          Gitlab.ee do
            get :security
            get :licenses
          end
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

      concerns :clusterable

      resources :environments, except: [:destroy] do
        member do
          post :stop
          get :terminal
          get :metrics
          get :additional_metrics
          get :metrics_dashboard
          get '/terminal.ws/authorize', to: 'environments#terminal_websocket_authorize', constraints: { format: nil }

          get '/prometheus/api/v1/*proxy_path', to: 'environments/prometheus_api#proxy', as: :prometheus_api

          Gitlab.ee do
            get :logs
          end
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

      Gitlab.ee do
        resources :protected_environments, only: [:create, :update, :destroy], constraints: { id: /\d+/ } do
          collection do
            get 'search'
          end
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

      namespace :serverless do
        scope :functions do
          get '/:environment_id/:id', to: 'functions#show'
          get '/:environment_id/:id/metrics', to: 'functions#metrics', as: :metrics
        end

        resources :functions, only: [:index]
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
                             constraints: { id: Gitlab::Regex.container_registry_tag_regex }
          end
        end
      end

      Gitlab.ee do
        namespace :security do
          resource :dashboard, only: [:show], controller: :dashboard
        end

        resources :vulnerability_feedback, only: [:index, :create, :update, :destroy], constraints: { id: /\d+/ }
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

          Gitlab.ee do
            post :export_csv
            get :service_desk
          end
        end

        Gitlab.ee do
          resources :issue_links, only: [:index, :create, :destroy], as: 'links', path: 'links'
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

      Gitlab.ee do
        resources :approvers, only: :destroy
        resources :approver_groups, only: :destroy
      end

      resources :runner_projects, only: [:create, :destroy]
      resources :badges, only: [:index] do
        collection do
          scope '*ref', constraints: { ref: Gitlab::PathRegex.git_reference_regex } do
            constraints format: /svg/ do
              # Keep around until 10.0, see gitlab-org/gitlab-ce#35307
              get :build, to: "badges#pipeline"
              get :pipeline
              get :coverage
            end
          end
        end
      end

      Gitlab.ee do
        resources :audit_events, only: [:index]
      end

      resources :error_tracking, only: [:index], controller: :error_tracking do
        collection do
          post :list_projects
        end
      end

      # Since both wiki and repository routing contains wildcard characters
      # its preferable to keep it below all other project routes
      draw :wiki
      draw :repository

      Gitlab.ee do
        resources :managed_licenses, only: [:index, :show, :new, :create, :edit, :update, :destroy]
      end
    end

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
  end

  # Legacy routes.
  # Introduced in 12.0.
  # Should be removed after 12.1
  scope(path: '*namespace_id',
        as: :namespace,
        namespace_id: Gitlab::PathRegex.full_namespace_route_regex) do
    scope(path: ':project_id',
          constraints: { project_id: Gitlab::PathRegex.project_route_regex },
          module: :projects,
          as: :project) do
      Gitlab::Routing.redirect_legacy_paths(self, :settings, :branches, :tags,
                                            :network, :graphs, :autocomplete_sources,
                                            :project_members, :deploy_keys, :deploy_tokens,
                                            :labels, :milestones, :services, :boards, :releases,
                                            :forks, :group_links, :import, :avatar)
    end
  end
end
