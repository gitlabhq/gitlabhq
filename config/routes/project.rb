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
    end

    scope module: :projects do
      scope constraints: { id: /.+\.git/, format: nil } do
        # Git HTTP clients ('git clone' etc.)
        get '/info/refs', to: 'git_http#info_refs'
        post '/git-upload-pack', to: 'git_http#git_upload_pack'
        post '/git-receive-pack', to: 'git_http#git_receive_pack'

        # Git LFS API (metadata)
        post '/info/lfs/objects/batch', to: 'lfs_api#batch'
        post '/info/lfs/objects', to: 'lfs_api#deprecated'
        get '/info/lfs/objects/*oid', to: 'lfs_api#deprecated'

        # GitLab LFS object storage
        scope constraints: { oid: /[a-f0-9]{64}/ } do
          get '/gitlab-lfs/objects/*oid', to: 'lfs_storage#download'

          scope constraints: { size: /[0-9]+/ } do
            put '/gitlab-lfs/objects/*oid/*size/authorize', to: 'lfs_storage#upload_authorize'
            put '/gitlab-lfs/objects/*oid/*size', to: 'lfs_storage#upload_finalize'
          end
        end
      end

      # Allow /info/refs, /info/refs?service=git-upload-pack, and
      # /info/refs?service=git-receive-pack, but nothing else.
      #
      git_http_handshake = lambda do |request|
        request.query_string.blank? ||
          request.query_string.match(/\Aservice=git-(upload|receive)-pack\z/)
      end

      ref_redirect = redirect do |params, request|
        path = "#{params[:namespace_id]}/#{params[:project_id]}.git/info/refs"
        path << "?#{request.query_string}" unless request.query_string.blank?
        path
      end

      get '/info/refs', constraints: git_http_handshake, to: ref_redirect

      # Blob routes:
      get '/new/*id', to: 'blob#new', constraints: { id: /.+/ }, as: 'new_blob'
      post '/create/*id', to: 'blob#create', constraints: { id: /.+/ }, as: 'create_blob'
      get '/edit/*id', to: 'blob#edit', constraints: { id: /.+/ }, as: 'edit_blob'
      put '/update/*id', to: 'blob#update', constraints: { id: /.+/ }, as: 'update_blob'
      post '/preview/*id', to: 'blob#preview', constraints: { id: /.+/ }, as: 'preview_blob'

      #
      # Templates
      #
      get '/templates/:template_type/:key' => 'templates#show', as: :template

      scope do
        get(
          '/blob/*id/diff',
          to: 'blob#diff',
          constraints: { id: /.+/, format: false },
          as: :blob_diff
        )
        get(
          '/blob/*id',
          to: 'blob#show',
          constraints: { id: /.+/, format: false },
          as: :blob
        )
        delete(
          '/blob/*id',
          to: 'blob#destroy',
          constraints: { id: /.+/, format: false }
        )
        put(
          '/blob/*id',
          to: 'blob#update',
          constraints: { id: /.+/, format: false }
        )
        post(
          '/blob/*id',
          to: 'blob#create',
          constraints: { id: /.+/, format: false }
        )
      end

      scope do
        get(
          '/raw/*id',
          to: 'raw#show',
          constraints: { id: /.+/, format: /(html|js)/ },
          as: :raw
        )
      end

      scope do
        get(
          '/tree/*id',
          to: 'tree#show',
          constraints: { id: /.+/, format: /(html|js)/ },
          as: :tree
        )
      end

      scope do
        get(
          '/find_file/*id',
          to: 'find_file#show',
          constraints: { id: /.+/, format: /html/ },
          as: :find_file
        )
      end

      scope do
        get(
          '/files/*id',
          to: 'find_file#list',
          constraints: { id: /(?:[^.]|\.(?!json$))+/, format: /json/ },
          as: :files
        )
      end

      scope do
        post(
          '/create_dir/*id',
            to: 'tree#create_dir',
            constraints: { id: /.+/ },
            as: 'create_dir'
        )
      end

      scope do
        get(
          '/blame/*id',
          to: 'blame#show',
          constraints: { id: /.+/, format: /(html|js)/ },
          as: :blame
        )
      end

      scope do
        get(
          '/commits/*id',
          to: 'commits#show',
          constraints: { id: /(?:[^.]|\.(?!atom$))+/, format: /atom/ },
          as: :commits
        )
      end

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

      WIKI_SLUG_ID = { id: /\S+/ } unless defined? WIKI_SLUG_ID

      scope do
        # Order matters to give priority to these matches
        get '/wikis/git_access', to: 'wikis#git_access'
        get '/wikis/pages', to: 'wikis#pages', as: 'wiki_pages'
        post '/wikis', to: 'wikis#create'

        get '/wikis/*id/history', to: 'wikis#history', as: 'wiki_history', constraints: WIKI_SLUG_ID
        get '/wikis/*id/edit', to: 'wikis#edit', as: 'wiki_edit', constraints: WIKI_SLUG_ID

        get '/wikis/*id', to: 'wikis#show', as: 'wiki', constraints: WIKI_SLUG_ID
        delete '/wikis/*id', to: 'wikis#destroy', constraints: WIKI_SLUG_ID
        put '/wikis/*id', to: 'wikis#update', constraints: WIKI_SLUG_ID
        post '/wikis/*id/preview_markdown', to: 'wikis#preview_markdown', constraints: WIKI_SLUG_ID, as: 'wiki_preview_markdown'
      end

      resource :repository, only: [:create] do
        member do
          get 'archive', constraints: { format: Gitlab::Regex.archive_formats_regex }
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

      resources :refs, only: [] do
        collection do
          get 'switch'
        end

        member do
          # tree viewer logs
          get 'logs_tree', constraints: { id: Gitlab::Regex.git_reference_regex }
          # Directories with leading dots erroneously get rejected if git
          # ref regex used in constraints. Regex verification now done in controller.
          get 'logs_tree/*path' => 'refs#logs_tree', as: :logs_file, constraints: {
            id: /.*/,
            path: /.*/
          }
        end
      end

      resources :merge_requests, concerns: :awardable, constraints: { id: /\d+/ } do
        member do
          get :commits
          get :diffs
          get :conflicts
          get :builds
          get :pipelines
          get :merge_check
          post :merge
          post :cancel_merge_when_build_succeeds
          get :ci_status
          post :toggle_subscription
          post :remove_wip
          get :diff_for_path
          post :resolve_conflicts
        end

        collection do
          get :branch_from
          get :branch_to
          get :update_branches
          get :diff_for_path
          post :bulk_update
          get :new_diffs, path: 'new/diffs'
        end

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

      resources :protected_branches, only: [:index, :show, :create, :update, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
      resources :variables, only: [:index, :show, :update, :create, :destroy]
      resources :triggers, only: [:index, :create, :destroy]

      resources :pipelines, only: [:index, :new, :create, :show] do
        collection do
          resource :pipelines_settings, path: 'settings', only: [:show, :update]
        end

        member do
          post :cancel
          post :retry
        end
      end

      resources :environments

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

      resource :board, only: [:show] do
        scope module: :boards do
          resources :issues, only: [:update]

          resources :lists, only: [:index, :create, :update, :destroy] do
            collection do
              post :generate
            end

            resources :issues, only: [:index]
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
    end
  end
end
