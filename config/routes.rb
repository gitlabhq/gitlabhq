require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'api/api'

Rails.application.routes.draw do
  if Gitlab::Sherlock.enabled?
    namespace :sherlock do
      resources :transactions, only: [:index, :show] do
        resources :queries, only: [:show]
        resources :file_samples, only: [:show]

        collection do
          delete :destroy_all
        end
      end
    end
  end

  if Rails.env.development?
    # Make the built-in Rails routes available in development, otherwise they'd
    # get swallowed by the `namespace/project` route matcher below.
    #
    # See https://git.io/va79N
    get '/rails/mailers'         => 'rails/mailers#index'
    get '/rails/mailers/:path'   => 'rails/mailers#preview'
    get '/rails/info/properties' => 'rails/info#properties'
    get '/rails/info/routes'     => 'rails/info#routes'
    get '/rails/info'            => 'rails/info#index'

    mount LetterOpenerWeb::Engine, at: '/rails/letter_opener'
  end

  concern :access_requestable do
    post :request_access, on: :collection
    post :approve_access_request, on: :member
  end

  namespace :ci do
    # CI API
    Ci::API::API.logger Rails.logger
    mount Ci::API::API => '/api'

    resource :lint, only: [:show, :create]

    resources :projects, only: [:index, :show] do
      member do
        get :status, to: 'projects#badge'
      end
    end

    root to: 'projects#index'
  end

  use_doorkeeper do
    controllers applications: 'oauth/applications',
                authorized_applications: 'oauth/authorized_applications',
                authorizations: 'oauth/authorizations'
  end

  namespace :oauth do
    scope path: 'geo', controller: :geo_auth, as: :geo do
      get 'auth'
      get 'callback'
      get 'logout'
    end
  end

  # Autocomplete
  get '/autocomplete/users' => 'autocomplete#users'
  get '/autocomplete/users/:id' => 'autocomplete#user'
  get '/autocomplete/projects' => 'autocomplete#projects'

  # Emojis
  resources :emojis, only: :index

  # Search
  get 'search' => 'search#show'
  get 'search/autocomplete' => 'search#autocomplete', as: :search_autocomplete

  # JSON Web Token
  get 'jwt/auth' => 'jwt#auth'

  # API
  API::API.logger Rails.logger
  mount API::API => '/api'

  constraint = lambda { |request| request.env['warden'].authenticate? and request.env['warden'].user.admin? }
  constraints constraint do
    mount Sidekiq::Web, at: '/admin/sidekiq', as: :sidekiq
  end

  # Health check
  get 'health_check(/:checks)' => 'health_check#index', as: :health_check

  # Help
  get 'help'           => 'help#index'
  get 'help/shortcuts' => 'help#shortcuts'
  get 'help/ui'        => 'help#ui'
  get 'help/*path'     => 'help#show', as: :help_page

  #
  # Global snippets
  #
  resources :snippets do
    member do
      get 'raw'
    end
  end

  get '/s/:username', to: redirect('/u/%{username}/snippets'),
                      constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }

  #
  # Invites
  #

  resources :invites, only: [:show], constraints: { id: /[A-Za-z0-9_-]+/ } do
    member do
      post :accept
      match :decline, via: [:get, :post]
    end
  end

  resources :sent_notifications, only: [], constraints: { id: /\h{32}/ } do
    member do
      get :unsubscribe
    end
  end

  #
  # Spam reports
  #
  resources :abuse_reports, only: [:new, :create]

  #
  # Notification settings
  #
  resources :notification_settings, only: [:create, :update]

  #
  # Import
  #
  namespace :import do
    resource :github, only: [:create, :new], controller: :github do
      post :personal_access_token
      get :status
      get :callback
      get :jobs
    end

    resource :gitlab, only: [:create], controller: :gitlab do
      get :status
      get :callback
      get :jobs
    end

    resource :bitbucket, only: [:create], controller: :bitbucket do
      get :status
      get :callback
      get :jobs
    end

    resource :gitorious, only: [:create, :new], controller: :gitorious do
      get :status
      get :callback
      get :jobs
    end

    resource :google_code, only: [:create, :new], controller: :google_code do
      get :status
      post :callback
      get :jobs

      get   :new_user_map,    path: :user_map
      post  :create_user_map, path: :user_map
    end

    resource :fogbugz, only: [:create, :new], controller: :fogbugz do
      get :status
      post :callback
      get :jobs

      get   :new_user_map,    path: :user_map
      post  :create_user_map, path: :user_map
    end

    resource :gitlab_project, only: [:create, :new] do
      post :create
    end
  end

  #
  # Uploads
  #

  scope path: :uploads do
    # Note attachments and User/Group/Project avatars
    get ":model/:mounted_as/:id/:filename",
        to:           "uploads#show",
        constraints:  { model: /note|user|group|project/, mounted_as: /avatar|attachment/, filename: /[^\/]+/ }

    # Appearance
    get ":model/:mounted_as/:id/:filename",
        to:           "uploads#show",
        constraints:  { model: /appearance/, mounted_as: /logo|header_logo/, filename: /.+/ }

    # Project markdown uploads
    get ":namespace_id/:project_id/:secret/:filename",
      to:           "projects/uploads#show",
      constraints:  { namespace_id: /[a-zA-Z.0-9_\-]+/, project_id: /[a-zA-Z.0-9_\-]+/, filename: /[^\/]+/ }
  end

  # Redirect old note attachments path to new uploads path.
  get "files/note/:id/:filename",
    to:           redirect("uploads/note/attachment/%{id}/%{filename}"),
    constraints:  { filename: /[^\/]+/ }

  #
  # Explore area
  #
  namespace :explore do
    resources :projects, only: [:index] do
      collection do
        get :trending
        get :starred
      end
    end

    resources :groups, only: [:index]
    resources :snippets, only: [:index]
    root to: 'projects#trending'
  end

  # Compatibility with old routing
  get 'public' => 'explore/projects#index'
  get 'public/projects' => 'explore/projects#index'

  #
  # Admin Area
  #
  namespace :admin do
    resources :users, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ } do
      resources :keys, only: [:show, :destroy]
      resources :identities, except: [:show]

      member do
        get :projects
        get :keys
        get :groups
        put :block
        put :unblock
        put :unlock
        put :confirm
        post :impersonate
        patch :disable_two_factor
        delete 'remove/:email_id', action: 'remove_email', as: 'remove_email'
      end
    end

    resources :push_rules, only: [:index, :update]

    resource :impersonation, only: :destroy

    resources :abuse_reports, only: [:index, :destroy]
    resources :spam_logs, only: [:index, :destroy]

    resources :applications

    resources :groups, constraints: { id: /[^\/]+/ } do
      member do
        put :members_update
      end
    end

    resources :deploy_keys, only: [:index, :new, :create, :destroy]

    resources :hooks, only: [:index, :create, :destroy] do
      get :test
    end

    resources :broadcast_messages, only: [:index, :edit, :create, :update, :destroy] do
      post :preview, on: :collection
    end

    resource :logs, only: [:show]
    resource :health_check, controller: 'health_check', only: [:show]
    resource :background_jobs, controller: 'background_jobs', only: [:show]
    resource :email, only: [:show, :create]
    resource :system_info, controller: 'system_info', only: [:show]
    resources :requests_profiles, only: [:index, :show], param: :name, constraints: { name: /.+\.html/ }

    resources :namespaces, path: '/projects', constraints: { id: /[a-zA-Z.0-9_\-]+/ }, only: [] do
      root to: 'projects#index', as: :projects

      resources(:projects,
                path: '/',
                constraints: { id: /[a-zA-Z.0-9_\-]+/ },
                only: [:index, :show]) do
        root to: 'projects#show'

        member do
          put :transfer
          post :repository_check
        end

        resources :runner_projects, only: [:create, :destroy]
      end
    end

    resource :appearances, only: [:show, :create, :update], path: 'appearance' do
      member do
        get :preview
        delete :logo
        delete :header_logos
      end
    end

    resource :application_settings, only: [:show, :update] do
      resources :services, only: [:index, :edit, :update]
      put :reset_runners_token
      put :reset_health_check_token
      put :clear_repository_check_states
    end

    resource :license, only: [:show, :new, :create, :destroy] do
      get :download, on: :member
    end

    resources :geo_nodes, only: [:index, :create, :destroy] do
      member do
        post :repair
      end
    end

    resources :labels

    resources :runners, only: [:index, :show, :update, :destroy] do
      member do
        get :resume
        get :pause
      end
    end

    resources :builds, only: :index do
      collection do
        post :cancel_all
      end
    end

    root to: 'dashboard#index'
  end

  #
  # Profile Area
  #
  resource :profile, only: [:show, :update] do
    member do
      get :audit_log
      get :applications, to: 'oauth/applications#index'

      put :reset_private_token
      put :update_username
    end

    scope module: :profiles do
      resource :account, only: [:show] do
        member do
          delete :unlink
        end
      end
      resource :notifications, only: [:show, :update]
      resource :password, only: [:new, :create, :edit, :update] do
        member do
          put :reset
        end
      end
      resource :preferences, only: [:show, :update]
      resources :keys, only: [:index, :show, :new, :create, :destroy]
      resources :emails, only: [:index, :create, :destroy]
      resource :avatar, only: [:destroy]

      resources :personal_access_tokens, only: [:index, :create] do
        member do
          put :revoke
        end
      end

      resource :two_factor_auth, only: [:show, :create, :destroy] do
        member do
          post :create_u2f
          post :codes
          patch :skip
        end
      end
    end
  end

  scope(path: 'u/:username',
        as: :user,
        constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ },
        controller: :users) do
    get :calendar
    get :calendar_activities
    get :groups
    get :projects
    get :contributed, as: :contributed_projects
    get :snippets
    get '/', action: :show
  end

  #
  # Dashboard Area
  #
  resource :dashboard, controller: 'dashboard', only: [] do
    get :issues
    get :merge_requests
    get :activity

    scope module: :dashboard do
      resources :milestones, only: [:index, :show]
      resources :labels, only: [:index]

      resources :groups, only: [:index]
      resources :snippets, only: [:index]

      resources :todos, only: [:index, :destroy] do
        collection do
          delete :destroy_all
        end
      end

      resources :projects, only: [:index] do
        collection do
          get :starred
        end
      end
    end

    root to: "dashboard/projects#index"
  end

  #
  # Groups Area
  #
  resources :groups, constraints: { id: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }  do
    member do
      get :issues
      get :merge_requests
      get :projects
      get :activity
    end

    collection do
      get :autocomplete
    end

    scope module: :groups do
      resource :analytics, only: [:show]
      resource :ldap, only: [] do
        member do
          put :reset_access
        end
      end

      resources :ldap_group_links, only: [:index, :create, :destroy]
      resources :group_members, only: [:index, :create, :update, :destroy], concerns: :access_requestable do
        post :resend_invite, on: :member
        delete :leave, on: :collection
      end

      resource :avatar, only: [:destroy]
      resources :milestones, constraints: { id: /[^\/]+/ }, only: [:index, :show, :update, :new, :create]
      resource :notification_setting, only: [:update]
      resources :audit_events, only: [:index]
    end

    resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ }, module: :groups do
      member do
        get :test
      end
    end
  end

  get  'unsubscribes/:email', to: 'unsubscribes#show', as: :unsubscribe
  post 'unsubscribes/:email', to: 'unsubscribes#create'
  resources :projects, constraints: { id: /[^\/]+/ }, only: [:index, :new, :create]

  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks,
                                    registrations: :registrations,
                                    passwords: :passwords,
                                    sessions: :sessions,
                                    confirmations: :confirmations }

  devise_scope :user do
    get '/users/auth/:provider/omniauth_error' => 'omniauth_callbacks#omniauth_error', as: :omniauth_error
    get '/users/almost_there' => 'confirmations#almost_there'
    get '/users/auth/kerberos_spnego/negotiate' => 'omniauth_kerberos_spnego#negotiate'
  end

  root to: "root#index"

  #
  # Project Area
  #
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
            post :cancel_builds
            post :retry_builds
            post :revert
            post :cherry_pick
            get :diff_for_path
          end
        end

        resource :pages, only: [:show, :destroy] do
          resources :domains, only: [:show, :new, :create, :destroy], controller: 'pages_domains'
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

        resources :snippets, constraints: { id: /\d+/ } do
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

        resources :merge_requests, constraints: { id: /\d+/ } do
          member do
            get :commits
            get :diffs
            get :builds
            get :merge_check
            post :merge
            post :cancel_merge_when_build_succeeds
            get :ci_status
            post :toggle_subscription
            post :approve
            post :rebase
            post :toggle_award_emoji
            post :remove_wip
            get :diff_for_path
          end

          collection do
            get :branch_from
            get :branch_to
            get :update_branches
            get :diff_for_path
          end
          resources :approvers, only: :destroy
        end

        resources :branches, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
        resources :tags, only: [:index, :show, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex } do
          resource :release, only: [:edit, :update]
        end
        resources :path_locks, only: [:index, :destroy] do
          collection do
            post :toggle
          end
        end

        resources :protected_branches, only: [:index, :show, :create, :update, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
        resources :variables, only: [:index, :show, :update, :create, :destroy]
        resources :triggers, only: [:index, :create, :destroy]
        resource :mirror, only: [:show, :update] do
          member do
            post :update_now
          end
        end
        resources :push_rules, constraints: { id: /\d+/ }

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

        resources :builds, only: [:index, :show], constraints: { id: /\d+/ } do
          collection do
            post :cancel_all
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

        resources :issues, constraints: { id: /\d+/ } do
          member do
            post :toggle_subscription
            post :toggle_award_emoji
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

        resources :group_links, only: [:index, :create, :destroy], constraints: { id: /\d+/ }

        resources :notes, only: [:index, :create, :destroy, :update], constraints: { id: /\d+/ } do
          member do
            post :toggle_award_emoji
            delete :delete_attachment
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

        resources :approvers, only: :destroy
        resources :runner_projects, only: [:create, :destroy]
        resources :badges, only: [:index] do
          collection do
            scope '*ref', constraints: { ref: Gitlab::Regex.git_reference_regex } do
              get :build, constraints: { format: /svg/ }
            end
          end
        end
        resources :audit_events, only: [:index]
      end
    end
  end

  # Get all keys of user
  get ':username.keys' => 'profiles/keys#get_keys', constraints: { username: /.*/ }

  get ':id' => 'namespaces#show', constraints: { id: /(?:[^.]|\.(?!atom$))+/, format: /atom/ }
end
