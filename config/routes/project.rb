resources :projects, constraints: { id: /[^\/]+/ }, only: [:index, :new, :create]

resources :namespaces, path: '/', constraints: { id: /[a-zA-Z.0-9_\-]+/ }, only: [] do
  resources(:projects, constraints: { id: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }, except:
            [:new, :create, :index], path: "/") do
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
      get :autocomplete_sources
      get :activity
      get :refs
      put :new_issue_address
    end

    scope module: :projects do
      draw :git_http

      #
      # Templates
      #
      get '/templates/:template_type/:key' => 'templates#show', as: :template

      resource  :avatar, only: [:show, :destroy]
      resources :commit, only: [:show], constraints: { id: /\h{7,40}/ } do
        member do
          get :branches
          get :builds
          get :pipelines
          post :cancel_builds
          post :retry_builds
          post :revert
          post :cherry_pick
          get :diff_for_path
        end
      end

      ## EE-specific
      resource :pages, only: [:show, :destroy] do
        resources :domains, only: [:show, :new, :create, :destroy], controller: 'pages_domains'
      end
      ## EE-specific

      resources :compare, only: [:index, :create] do
        collection do
          get :diff_for_path
        end
      end

      get '/compare/:from...:to', to: 'compare#show', as: 'compare', constraints: { from: /.+/, to: /.+/ }

      # Don't use format parameter as file extension (old 3.0.x behavior)
      # See http://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments
      scope format: false do
        resources :network, only: [:show], constraints: { id: Gitlab::Regex.git_reference_regex }

        resources :graphs, only: [:show], constraints: { id: Gitlab::Regex.git_reference_regex } do
          member do
            get :commits
            get :ci
            get :languages
          end
        end
      end

      resources :snippets, concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          get 'raw'
        end
      end

      resources :services, constraints: { id: /[^\/]+/ }, only: [:index, :edit, :update] do
        member do
          get :test
        end
      end

      resources :deploy_keys, constraints: { id: /\d+/ }, only: [:index, :new, :create] do
        member do
          put :enable
          put :disable
        end
      end

      resources :forks, only: [:index, :new, :create]
      resource :import, only: [:new, :create, :show]

      resources :merge_requests, concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          get :commits
          get :diffs
          get :conflicts
          get :conflict_for_path
          get :builds
          get :pipelines
          get :merge_check
          post :merge
          post :cancel_merge_when_build_succeeds
          get :ci_status
          get :ci_environments_status
          post :toggle_subscription

          ## EE-specific
          post :approve
          post :rebase
          ## EE-specific

          post :remove_wip
          get :diff_for_path
          post :resolve_conflicts
          post :assign_related_issues
        end

        collection do
          get :branch_from
          get :branch_to
          get :update_branches
          get :diff_for_path
          post :bulk_update
          get :new_diffs, path: 'new/diffs'
        end

        ## EE-specific
        resources :approvers, only: :destroy
        resources :approver_groups, only: :destroy
        ## EE-specific

        resources :discussions, only: [], constraints: { id: /\h{40}/ } do
          member do
            post :resolve
            delete :resolve, action: :unresolve
          end
        end
      end

      resources :branches, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
      resources :tags, only: [:index, :show, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex } do
        resource :release, only: [:edit, :update]
      end

      ## EE-specific
      resources :path_locks, only: [:index, :destroy] do
        collection do
          post :toggle
        end
      end

      resources :protected_branches, only: [:index, :show, :create, :update, :destroy, :patch], constraints: { id: Gitlab::Regex.git_reference_regex } do
        scope module: :protected_branches do
          resources :merge_access_levels, only: [:destroy]
          resources :push_access_levels, only: [:destroy]
        end
      end
      ## EE-specific

      resources :variables, only: [:index, :show, :update, :create, :destroy]
      resources :triggers, only: [:index, :create, :destroy]

      ## EE-specific
      resource :mirror, only: [:show, :update] do
        member do
          post :update_now
        end
      end
      resources :push_rules, constraints: { id: /\d+/ }
      ## EE-specific

      resources :pipelines, only: [:index, :new, :create, :show] do
        collection do
          resource :pipelines_settings, path: 'settings', only: [:show, :update]
        end

        member do
          post :cancel
          post :retry
        end
      end

      resources :environments, except: [:destroy] do
        member do
          post :stop
        end
      end

      resource :cycle_analytics, only: [:show]

      resources :builds, only: [:index, :show], constraints: { id: /\d+/ } do
        collection do
          post :cancel_all

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
          post :retry
          post :play
          post :erase
          get :trace
          get :raw
        end

        resource :artifacts, only: [] do
          get :download
          get :browse, path: 'browse(/*path)', format: false
          get :file, path: 'file/*path', format: false
          post :keep
        end
      end

      resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ } do
        member do
          get :test
        end
      end

      resources :container_registry, only: [:index, :destroy], constraints: { id: Gitlab::Regex.container_registry_reference_regex }

      resources :milestones, constraints: { id: /\d+/ } do
        member do
          put :sort_issues
          put :sort_merge_requests
        end
      end

      resources :labels, except: [:show], constraints: { id: /\d+/ } do
        collection do
          post :generate
          post :set_priorities
        end

        member do
          post :toggle_subscription
          delete :remove_priority
        end
      end

      resources :issues, concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          post :toggle_subscription
          post :mark_as_spam
          get :referenced_merge_requests
          get :related_branches
          get :can_create_branch
        end
        collection do
          post  :bulk_update
        end
      end

      resources :project_members, except: [:show, :new, :edit], constraints: { id: /[a-zA-Z.\/0-9_\-#%+]+/ }, concerns: :access_requestable do
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

      resources :group_links, only: [:index, :create, :update, :destroy], constraints: { id: /\d+/ }

      resources :notes, only: [:index, :create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          delete :delete_attachment
          post :resolve
          delete :resolve, action: :unresolve
        end
      end

      resources :boards, only: [:index, :show, :create, :update, :destroy] do
        scope module: :boards do
          resources :issues, only: [:update]

          resources :lists, only: [:index, :create, :update, :destroy] do
            collection do
              post :generate
            end

            resources :issues, only: [:index, :create]
          end
        end
      end

      resources :todos, only: [:create]

      resources :uploads, only: [:create] do
        collection do
          get ":secret/:filename", action: :show, as: :show, constraints: { filename: /[^\/]+/ }
        end
      end

      resources :runners, only: [:index, :edit, :update, :destroy, :show] do
        member do
          get :resume
          get :pause
        end

        collection do
          post :toggle_shared_runners
        end
      end

      ## EE-specific
      resources :approvers, only: :destroy
      resources :approver_groups, only: :destroy
      ## EE-specific

      resources :runner_projects, only: [:create, :destroy]
      resources :badges, only: [:index] do
        collection do
          scope '*ref', constraints: { ref: Gitlab::Regex.git_reference_regex } do
            constraints format: /svg/ do
              get :build
              get :coverage
            end
          end
        end
      end

      ## EE-specific
      resources :audit_events, only: [:index]
      ## EE-specific

      # Since both wiki and repository routing contains wildcard characters
      # its preferable to keep it below all other project routes
      draw :wiki
      draw :repository
    end
  end
end
