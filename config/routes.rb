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

  namespace :ci do
    # CI API
    Ci::API::API.logger Rails.logger
    mount Ci::API::API => '/api'

    resource :lint, only: [:show, :create]

    resources :projects do
      member do
        get :status, to: 'projects#badge'
        get :integration
      end
    end

    root to: 'projects#index'
  end

  use_doorkeeper do
    controllers applications: 'oauth/applications',
                authorized_applications: 'oauth/authorized_applications',
                authorizations: 'oauth/authorizations'
  end

  # Autocomplete
  get '/autocomplete/users' => 'autocomplete#users'
  get '/autocomplete/users/:id' => 'autocomplete#user'

  # Emojis
  resources :emojis, only: :index

  # Search
  get 'search' => 'search#show'
  get 'search/autocomplete' => 'search#autocomplete', as: :search_autocomplete

  # API
  API::API.logger Rails.logger
  mount API::API => '/api'

  constraint = lambda { |request| request.env['warden'].authenticate? and request.env['warden'].user.admin? }
  constraints constraint do
    mount Sidekiq::Web, at: '/admin/sidekiq', as: :sidekiq
  end

  # Enable Grack support
  mount Grack::AuthSpawner, at: '/', constraints: lambda { |request| /[-\/\w\.]+\.git\//.match(request.path_info) }, via: [:get, :post, :put]

  # Help
  get 'help'                  => 'help#index'
  get 'help/:category/:file'  => 'help#show', as: :help_page, constraints: { category: /.*/, file: /[^\/\.]+/ }
  get 'help/shortcuts'
  get 'help/ui'               => 'help#ui'

  #
  # Global snippets
  #
  resources :snippets do
    member do
      get 'raw'
    end
  end

  get '/s/:username' => 'snippets#index', as: :user_snippets, constraints: { username: /.*/ }

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

  # Spam reports
  resources :abuse_reports, only: [:new, :create]

  #
  # Import
  #
  namespace :import do
    resource :github, only: [:create, :new], controller: :github do
      get :status
      get :callback
      get :jobs
    end

    resource :gitlab, only: [:create, :new], controller: :gitlab do
      get :status
      get :callback
      get :jobs
    end

    resource :bitbucket, only: [:create, :new], controller: :bitbucket do
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

      delete 'stop_impersonation' => 'impersonation#destroy', on: :collection

      member do
        get :projects
        get :keys
        get :groups
        put :team_update
        put :block
        put :unblock
        put :unlock
        put :confirm
        post 'impersonate' => 'impersonation#create'
        patch :disable_two_factor
        delete 'remove/:email_id', action: 'remove_email', as: 'remove_email'
      end
    end

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
    resource :background_jobs, controller: 'background_jobs', only: [:show]

    resources :namespaces, path: '/projects', constraints: { id: /[a-zA-Z.0-9_\-]+/ }, only: [] do
      root to: 'projects#index', as: :projects

      resources(:projects,
                path: '/',
                constraints: { id: /[a-zA-Z.0-9_\-]+/ },
                only: [:index, :show]) do
        root to: 'projects#show'

        member do
          put :transfer
        end

        resources :runner_projects
      end
    end

    resource :appearances, path: 'appearance' do
      member do
        get :preview
        delete :logo
        delete :header_logos
      end
    end

    resource :application_settings, only: [:show, :update] do
      resources :services
      put :reset_runners_token
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
      get :applications

      put :reset_private_token
      put :update_username
    end

    scope module: :profiles do
      resource :account, only: [:show, :update] do
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
      resources :keys, except: [:new]
      resources :emails, only: [:index, :create, :destroy]
      resource :avatar, only: [:destroy]
      resource :two_factor_auth, only: [:new, :create, :destroy] do
        member do
          post :codes
          patch :skip
        end
      end
    end
  end

  get 'u/:username/calendar' => 'users#calendar', as: :user_calendar,
      constraints: { username: /.*/ }

  get 'u/:username/calendar_activities' => 'users#calendar_activities', as: :user_calendar_activities,
      constraints: { username: /.*/ }

  get 'u/:username/groups' => 'users#groups', as: :user_groups,
      constraints: { username: /.*/ }

  get 'u/:username/projects' => 'users#projects', as: :user_projects,
      constraints: { username: /.*/ }

  get 'u/:username/contributed' => 'users#contributed', as: :user_contributed_projects,
      constraints: { username: /.*/ }

  get '/u/:username' => 'users#show', as: :user,
      constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }

  #
  # Dashboard Area
  #
  resource :dashboard, controller: 'dashboard', only: [] do
    get :issues
    get :merge_requests
    get :activity

    scope module: :dashboard do
      resources :milestones, only: [:index, :show]

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

    scope module: :groups do
      resources :group_members, only: [:index, :create, :update, :destroy] do
        post :resend_invite, on: :member
        delete :leave, on: :collection
      end

      resource :avatar, only: [:destroy]
      resources :milestones, constraints: { id: /[^\/]+/ }, only: [:index, :show, :update, :new, :create]
    end
  end

  resources :projects, constraints: { id: /[^\/]+/ }, only: [:index, :new, :create]

  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks, registrations: :registrations , passwords: :passwords, sessions: :sessions, confirmations: :confirmations }

  devise_scope :user do
    get '/users/auth/:provider/omniauth_error' => 'omniauth_callbacks#omniauth_error', as: :omniauth_error
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
        post :markdown_preview
        get :autocomplete_sources
        get :activity
      end

      scope module: :projects do
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
          end
        end

        resources :compare, only: [:index, :create]
        resources :network, only: [:show], constraints: { id: /(?:[^.]|\.(?!json$))+/, format: /json/ }

        resources :graphs, only: [:show], constraints: { id: /(?:[^.]|\.(?!json$))+/, format: /json/ } do
          member do
            get :commits
            get :ci
            get :languages
          end
        end

        get '/compare/:from...:to' => 'compare#show', :as => 'compare',
            :constraints => { from: /.+/, to: /.+/ }

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
        end

        resource :repository, only: [:show, :create] do
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

        resources :merge_requests, constraints: { id: /\d+/ }, except: [:destroy] do
          member do
            get :commits
            get :diffs
            get :builds
            get :merge_check
            post :merge
            post :cancel_merge_when_build_succeeds
            get :ci_status
            post :toggle_subscription
          end

          collection do
            get :branch_from
            get :branch_to
            get :update_branches
          end
        end

        resources :branches, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
        resources :tags, only: [:index, :show, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex } do
          resource :release, only: [:edit, :update]
        end

        resources :protected_branches, only: [:index, :create, :update, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
        resource :variables, only: [:show, :update]
        resources :triggers, only: [:index, :create, :destroy]

        resources :builds, only: [:index, :show], constraints: { id: /\d+/ } do
          collection do
            post :cancel_all
          end

          member do
            get :status
            post :cancel
            post :retry
            post :erase
          end

          resource :artifacts, only: [] do
            get :download
            get :browse, path: 'browse(/*path)', format: false
            get :file, path: 'file/*path', format: false
          end
        end

        resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ } do
          member do
            get :test
          end
        end

        resources :milestones, constraints: { id: /\d+/ } do
          member do
            put :sort_issues
            put :sort_merge_requests
          end
        end

        resources :labels, constraints: { id: /\d+/ } do
          collection do
            post :generate
          end
        end

        resources :issues, constraints: { id: /\d+/ }, except: [:destroy] do
          member do
            post :toggle_subscription
          end
          collection do
            post  :bulk_update
          end
        end

        resources :project_members, except: [:new, :edit], constraints: { id: /[a-zA-Z.\/0-9_\-#%+]+/ } do
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

        resources :notes, only: [:index, :create, :destroy, :update], constraints: { id: /\d+/ } do
          member do
            delete :delete_attachment
          end

          collection do
            post :award_toggle
          end
        end

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
        resources :badges, only: [], path: 'badges/*ref',
                           constraints: { ref: Gitlab::Regex.git_reference_regex } do
          collection do
            get :build, constraints: { format: /svg/ }
          end
        end
      end
    end
  end

  # Get all keys of user
  get ':username.keys' => 'profiles/keys#get_keys' , constraints: { username: /.*/ }

  get ':id' => 'namespaces#show', constraints: { id: /(?:[^.]|\.(?!atom$))+/, format: /atom/ }
end
