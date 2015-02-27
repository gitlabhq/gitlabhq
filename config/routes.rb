require 'sidekiq/web'
require 'api/api'

Gitlab::Application.routes.draw do
  use_doorkeeper do
    controllers applications: 'oauth/applications',
                authorized_applications: 'oauth/authorized_applications',
                authorizations: 'oauth/authorizations'
  end
  #
  # Search
  #
  get 'search' => 'search#show'
  get 'search/autocomplete' => 'search#autocomplete', as: :search_autocomplete

  # API
  API::API.logger Rails.logger
  mount API::API => '/api'

  # Get all keys of user
  get ':username.keys' => 'profiles/keys#get_keys' , constraints: { username: /.*/ }

  constraint = lambda { |request| request.env['warden'].authenticate? and request.env['warden'].user.admin? }
  constraints constraint do
    mount Sidekiq::Web, at: '/admin/sidekiq', as: :sidekiq
  end

  # Enable Grack support
  mount Grack::Bundle.new({
    git_path:     Gitlab.config.git.bin_path,
    project_root: Gitlab.config.gitlab_shell.repos_path,
    upload_pack:  Gitlab.config.gitlab_shell.upload_pack,
    receive_pack: Gitlab.config.gitlab_shell.receive_pack
  }), at: '/', constraints: lambda { |request| /[-\/\w\.]+\.git\//.match(request.path_info) }, via: [:get, :post]

  #
  # Help
  #

  get 'help'                  => 'help#index'
  get 'help/:category/:file'  => 'help#show', as: :help_page
  get 'help/shortcuts'

  #
  # Global snippets
  #
  resources :snippets do
    member do
      get 'raw'
    end
  end
  get '/s/:username' => 'snippets#user_index', as: :user_snippets, constraints: { username: /.*/ }


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
  end

  #
  # Uploads
  #

  scope path: :uploads do
    # Note attachments and User/Group/Project avatars
    get ":model/:mounted_as/:id/:filename",
        to:           "uploads#show",
        constraints:  { model: /note|user|group|project/, mounted_as: /avatar|attachment/, filename: /.+/ }

    # Project markdown uploads
    get ":namespace_id/:project_id/:secret/:filename",
      to:           "projects/uploads#show",
      constraints:  { namespace_id: /[a-zA-Z.0-9_\-]+/, project_id: /[a-zA-Z.0-9_\-]+/, filename: /.+/ }
  end

  get "files/note/:id/:filename",
    to:           redirect("uploads/note/attachment/%{id}/%{filename}"),
    constraints:  { filename: /.+/ }

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
      member do
        put :team_update
        put :block
        put :unblock
        delete 'remove/:email_id', action: 'remove_email', as: 'remove_email'
      end
    end

    resources :applications

    resources :groups, constraints: { id: /[^\/]+/ } do
      member do
        put :project_teams_update
      end
    end

    resources :hooks, only: [:index, :create, :destroy] do
      get :test
    end

    resources :broadcast_messages, only: [:index, :create, :destroy]
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
      end
    end

    resource :application_settings, only: [:show, :update] do
      resources :services
    end

    root to: 'dashboard#index'
  end

  #
  # Profile Area
  #
  resource :profile, only: [:show, :update] do
    member do
      get :history
      get :design
      get :applications

      put :reset_private_token
      put :update_username
    end

    scope module: :profiles do
      resource :account, only: [:show, :update]
      resource :notifications, only: [:show, :update]
      resource :password, only: [:new, :create, :edit, :update] do
        member do
          put :reset
        end
      end
      resources :keys
      resources :emails, only: [:index, :create, :destroy]
      resources :groups, only: [:index] do
        member do
          delete :leave
        end
      end
      resource :avatar, only: [:destroy]
    end
  end

  get 'u/:username/calendar' => 'users#calendar', as: :user_calendar,
      constraints: { username: /(?:[^.]|\.(?!atom$))+/, format: /atom/ }

  get '/u/:username' => 'users#show', as: :user,
      constraints: { username: /(?:[^.]|\.(?!atom$))+/, format: /atom/ }

  #
  # Dashboard Area
  #
  resource :dashboard, controller: 'dashboard', only: [:show] do
    member do
      get :projects
      get :issues
      get :merge_requests
    end
  end

  #
  # Groups Area
  #
  resources :groups, constraints: { id: /(?:[^.]|\.(?!atom$))+/, format: /atom/ }  do
    member do
      get :issues
      get :merge_requests
      get :members
      get :projects
    end

    scope module: :groups do
      resources :group_members, only: [:create, :update, :destroy]
      resource :avatar, only: [:destroy]
      resources :milestones
    end
  end

  resources :projects, constraints: { id: /[^\/]+/ }, only: [:new, :create]

  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks, registrations: :registrations , passwords: :passwords, sessions: :sessions, confirmations: :confirmations }

  devise_scope :user do
    get '/users/auth/:provider/omniauth_error' => 'omniauth_callbacks#omniauth_error', as: :omniauth_error
  end

  root to: "dashboard#show"

  #
  # Project Area
  #
  resources :namespaces, path: '/', constraints: { id: /[a-zA-Z.0-9_\-]+/ }, only: [] do
    resources(:projects, constraints: { id: /[a-zA-Z.0-9_\-]+/ }, except:
              [:new, :create, :index], path: "/") do
      member do
        put :transfer
        post :archive
        post :unarchive
        post :toggle_star
        post :markdown_preview
        get :autocomplete_sources
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
        resource  :avatar,    only: [:show, :destroy]

        resources :commit,    only: [:show], constraints: { id: /[[:alnum:]]{6,40}/ } do
          get :branches, on: :member
        end

        resources :commits,   only: [:show], constraints: { id: /(?:[^.]|\.(?!atom$))+/, format: /atom/ }
        resources :compare,   only: [:index, :create]

        scope do
          get(
            '/blame/*id',
            to: 'blame#show',
            constraints: { id: /.+/, format: /(html|js)/ },
            as: :blame
          )
        end

        resources :network,   only: [:show], constraints: { id: /(?:[^.]|\.(?!json$))+/, format: /json/ }
        resources :graphs,    only: [:show], constraints: { id: /(?:[^.]|\.(?!json$))+/, format: /json/ } do
          member do
            get :commits
          end
        end

        get '/compare/:from...:to' => 'compare#show', :as => 'compare',
            :constraints => { from: /.+/, to: /.+/ }

        resources :snippets, constraints: { id: /\d+/ } do
          member do
            get 'raw'
          end
        end

        resources :wikis, only: [:show, :edit, :destroy, :create], constraints: { id: /[a-zA-Z.0-9_\-\/]+/ } do
          collection do
            get :pages
            put ':id' => 'wikis#update'
            get :git_access
          end

          member do
            get 'history'
          end
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

        resources :deploy_keys, constraints: { id: /\d+/ } do
          member do
            put :enable
            put :disable
          end
        end

        resource :fork, only: [:new, :create]
        resource :import, only: [:new, :create, :show]

        resources :refs, only: [] do
          collection do
            get 'switch'
          end

          member do
            # tree viewer logs
            get 'logs_tree', constraints: { id: Gitlab::Regex.git_reference_regex }
            get 'logs_tree/:path' => 'refs#logs_tree', as: :logs_file, constraints: {
              id: Gitlab::Regex.git_reference_regex,
              path: /.*/
            }
          end
        end

        resources :merge_requests, constraints: { id: /\d+/ }, except: [:destroy] do
          member do
            get :diffs
            post :automerge
            get :automerge_check
            get :ci_status
          end

          collection do
            get :branch_from
            get :branch_to
            get :update_branches
          end
        end

        resources :branches, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
        resources :tags, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
        resources :protected_branches, only: [:index, :create, :update, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }

        resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ } do
          member do
            get :test
          end
        end

        resources :team, controller: 'team_members', only: [:index]
        resources :milestones, except: [:destroy], constraints: { id: /\d+/ } do
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
          collection do
            post  :bulk_update
          end
        end

        resources :team_members, except: [:index, :edit], constraints: { id: /[a-zA-Z.\/0-9_\-#%+]+/ } do
          collection do
            delete :leave

            # Used for import team
            # from another project
            get :import
            post :apply_import
          end
        end

        resources :notes, only: [:index, :create, :destroy, :update], constraints: { id: /\d+/ } do
          member do
            delete :delete_attachment
          end
        end

        resources :uploads, only: [:create] do
          collection do
            get ":secret/:filename", action: :show, as: :show, constraints: { filename: /.+/ }
          end
        end
      end

    end
  end

  get ':id' => 'namespaces#show', constraints: { id: /(?:[^.]|\.(?!atom$))+/, format: /atom/ }
end
