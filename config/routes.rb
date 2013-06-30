require 'sidekiq/web'
require 'api/api'

Gitlab::Application.routes.draw do
  #
  # Search
  #
  get 'search' => "search#show"

  # API
  API::API.logger Rails.logger
  mount API::API => '/api'

  constraint = lambda { |request| request.env["warden"].authenticate? and request.env['warden'].user.admin? }
  constraints constraint do
    mount Sidekiq::Web, at: "/admin/sidekiq", as: :sidekiq
  end

  # Enable Grack support
  mount Grack::Bundle.new({
    git_path:     Gitlab.config.git.bin_path,
    project_root: Gitlab.config.gitlab_shell.repos_path,
    upload_pack:  Gitlab.config.gitlab_shell.upload_pack,
    receive_pack: Gitlab.config.gitlab_shell.receive_pack
  }), at: '/', constraints: lambda { |request| /[-\/\w\.]+\.git\//.match(request.path_info) }

  #
  # Help
  #
  get 'help'                => 'help#index'
  get 'help/api'            => 'help#api'
  get 'help/api/:category'  => 'help#api', as: 'help_api_file'
  get 'help/markdown'       => 'help#markdown'
  get 'help/permissions'    => 'help#permissions'
  get 'help/public_access'  => 'help#public_access'
  get 'help/raketasks'      => 'help#raketasks'
  get 'help/ssh'            => 'help#ssh'
  get 'help/system_hooks'   => 'help#system_hooks'
  get 'help/web_hooks'      => 'help#web_hooks'
  get 'help/workflow'       => 'help#workflow'

  #
  # Global snippets
  #
  resources :snippets do
    member do
      get "raw"
    end
  end
  get "/s/:username" => "snippets#user_index", as: :user_snippets, constraints: { username: /.*/ }

  #
  # Public namespace
  #
  namespace :public do
    resources :projects, only: [:index]
    root to: "projects#index"
  end

  #
  # Attachments serving
  #
  get 'files/:type/:id/:filename' => 'files#download', constraints: { id: /\d+/, type: /[a-z]+/, filename:  /.+/ }

  #
  # Admin Area
  #
  namespace :admin do
    resources :users, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ } do
      member do
        put :team_update
        put :block
        put :unblock
      end
    end

    resources :groups, constraints: { id: /[^\/]+/ } do
      member do
        put :project_update
        put :project_teams_update
        delete :remove_project
      end
    end

    resources :teams, constraints: { id: /[^\/]+/ } do
      scope module: :teams do
        resources :members,   only: [:edit, :update, :destroy, :new, :create]
        resources :projects,  only: [:edit, :update, :destroy, :new, :create], constraints: { id: /[a-zA-Z.\/0-9_\-]+/ }
      end
    end

    resources :hooks, only: [:index, :create, :destroy] do
      get :test
    end

    resource :logs, only: [:show]
    resource :background_jobs, controller: 'background_jobs', only: [:show]

    resources :projects, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ }, only: [:index, :show] do
      scope module: :projects, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ } do
        resources :members, only: [:edit, :update, :destroy]
      end
    end

    root to: "dashboard#index"
  end

  get "errors/githost"

  #
  # Profile Area
  #
  resource :profile, only: [:show, :update] do
    member do
      get :account
      get :history
      get :token
      get :design

      put :update_password
      put :reset_private_token
      put :update_username
    end

    resource :notifications
    resource :password
  end

  resources :keys
  match "/u/:username" => "users#show", as: :user, constraints: { username: /.*/ }



  #
  # Dashboard Area
  #
  resource :dashboard, controller: "dashboard" do
    member do
      get :projects
      get :issues
      get :merge_requests
    end
  end

  #
  # Groups Area
  #
  resources :groups, constraints: {id: /(?:[^.]|\.(?!atom$))+/, format: /atom/}  do
    member do
      get :issues
      get :merge_requests
      get :search
      get :people
      post :team_members
    end
  end

  #
  # Teams Area
  #
  resources :teams, constraints: {id: /(?:[^.]|\.(?!atom$))+/, format: /atom/} do
    member do
      get :issues
      get :merge_requests
    end
    scope module: :teams do
      resources :members,   only: [:index, :new, :create, :edit, :update, :destroy]
      resources :projects,  only: [:index, :new, :create, :edit, :update, :destroy], constraints: { id: /[a-zA-Z.0-9_\-\/]+/ }
    end
  end

  resources :projects, constraints: { id: /[^\/]+/ }, only: [:new, :create]

  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks, registrations: :registrations }

  #
  # Project Area
  #
  resources :projects, constraints: { id: /(?:[a-zA-Z.0-9_\-]+\/)?[a-zA-Z.0-9_\-]+/ }, except: [:new, :create, :index], path: "/" do
    member do
      put :transfer
      post :fork
      get :autocomplete_sources
    end

    resources :blob,    only: [:show], constraints: {id: /.+/}
    resources :raw,    only: [:show], constraints: {id: /.+/}
    resources :tree,    only: [:show], constraints: {id: /.+/, format: /(html|js)/ }
    resources :edit_tree,    only: [:show, :update], constraints: {id: /.+/}, path: 'edit'
    resources :commit,  only: [:show], constraints: {id: /[[:alnum:]]{6,40}/}
    resources :commits, only: [:show], constraints: {id: /(?:[^.]|\.(?!atom$))+/, format: /atom/}
    resources :compare, only: [:index, :create]
    resources :blame,   only: [:show], constraints: {id: /.+/}
    resources :network,   only: [:show], constraints: {id: /(?:[^.]|\.(?!json$))+/, format: /json/}
    resources :graphs, only: [:show], constraints: {id: /(?:[^.]|\.(?!json$))+/, format: /json/}
    match "/compare/:from...:to" => "compare#show", as: "compare", via: [:get, :post], constraints: {from: /.+/, to: /.+/}

    scope module: :projects do
      resources :snippets do
        member do
          get "raw"
        end
      end
    end

    resources :wikis, only: [:show, :edit, :destroy, :create] do
      collection do
        get :pages
        put ':id' => 'wikis#update'
        get :git_access
      end

      member do
        get "history"
      end
    end

    resource :wall, only: [:show] do
      member do
        get 'notes'
      end
    end

    resource :repository do
      member do
        get "branches"
        get "tags"
        get "stats"
        get "archive"
      end
    end

    resources :services, constraints: { id: /[^\/]+/ }, only: [:index, :edit, :update] do
      member do
        get :test
      end
    end

    resources :deploy_keys do
      member do
        put :enable
        put :disable
      end
    end

    resources :protected_branches, only: [:index, :create, :destroy]

    resources :refs, only: [] do
      collection do
        get "switch"
      end

      member do
        # tree viewer logs
        get "logs_tree", constraints: { id: /[a-zA-Z.\/0-9_\-#%+]+/ }
        get "logs_tree/:path" => "refs#logs_tree",
          as: :logs_file,
          constraints: {
            id:   /[a-zA-Z.0-9\/_\-#%+]+/,
            path: /.*/
          }
      end
    end

    resources :merge_requests, constraints: {id: /\d+/}, except: [:destroy] do
      member do
        get :diffs
        get :automerge
        get :automerge_check
        get :ci_status
      end

      collection do
        get :branch_from
        get :branch_to
      end
    end

    resources :hooks, only: [:index, :create, :destroy] do
      member do
        get :test
      end
    end

    resources :team, controller: 'team_members', only: [:index]
    resources :milestones, except: [:destroy]

    resources :labels, only: [:index] do
      collection do
        post :generate
      end
    end

    resources :issues, except: [:destroy] do
      collection do
        post  :bulk_update
      end
    end

    resources :team_members, except: [:index, :edit] do
      collection do

        # Used for import team
        # from another project
        get :import
        post :apply_import
      end
    end

    scope module: :projects do
      resources :teams, only: [] do
        collection do
          get :available
          post :assign
        end
        member do
          delete :resign
        end
      end
    end

    resources :notes, only: [:index, :create, :destroy] do
      collection do
        post :preview
      end
    end
  end

  root to: "dashboard#show"
end
