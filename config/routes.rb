Gitlab::Application.routes.draw do
  #
  # Search
  #
  get 'search' => "search#show"

  # API
  require 'api'
  mount Gitlab::API => '/api'

  # Optionally, enable Resque here
  require 'resque/server'
  mount Resque::Server => '/info/resque', as: 'resque'

  # Enable Grack support
  mount Grack::Bundle.new({
    git_path:     Gitlab.config.git.bin_path,
    project_root: Gitlab.config.gitolite.repos_path,
    upload_pack:  Gitlab.config.gitolite.upload_pack,
    receive_pack: Gitlab.config.gitolite.receive_pack
  }), at: '/:path', constraints: { path: /[-\/\w\.-]+\.git/ }

  #
  # Help
  #
  get 'help'              => 'help#index'
  get 'help/permissions'  => 'help#permissions'
  get 'help/workflow'     => 'help#workflow'
  get 'help/api'          => 'help#api'
  get 'help/web_hooks'    => 'help#web_hooks'
  get 'help/system_hooks' => 'help#system_hooks'
  get 'help/markdown'     => 'help#markdown'
  get 'help/ssh'          => 'help#ssh'
  get 'help/raketasks'    => 'help#raketasks'

  #
  # Admin Area
  #
  namespace :admin do
    resources :users do
      member do
        put :team_update
        put :block
        put :unblock
      end
    end
    resources :groups, constraints: { id: /[^\/]+/ } do
      member do
        put :project_update
        delete :remove_project
      end
    end
    resources :projects, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ }, except: [:new, :create] do
      member do
        get :team
        put :team_update
      end
    end
    resources :team_members, only: [:edit, :update, :destroy]
    resources :hooks, only: [:index, :create, :destroy] do
      get :test
    end
    resource :logs, only: [:show]
    resource :resque, controller: 'resque', only: [:show]
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
  end

  resources :keys

  #
  # Dashboard Area
  #
  get "dashboard"                => "dashboard#index"
  get "dashboard/issues"         => "dashboard#issues"
  get "dashboard/merge_requests" => "dashboard#merge_requests"


  #
  # Groups Area
  #
  resources :groups, constraints: { id: /[^\/]+/ }, only: [:show] do
    member do
      get :issues
      get :merge_requests
      get :search
      get :people
    end
  end

  resources :projects, constraints: { id: /[^\/]+/ }, only: [:new, :create]

  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks }

  #
  # Project Area
  #
  resources :projects, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ }, except: [:new, :create, :index], path: "/" do
    member do
      get "wall"
      get "graph"
      get "files"
    end

    resources :wikis, only: [:show, :edit, :destroy, :create] do
      collection do
        get :pages
      end

      member do
        get "history"
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

    resources :deploy_keys
    resources :protected_branches, only: [:index, :create, :destroy]

    resources :refs, only: [], path: "/" do
      collection do
        get "switch"
      end

      member do
        # tree viewer logs
        get "logs_tree", constraints: { id: /[a-zA-Z.\/0-9_\-]+/ }
        get "logs_tree/:path" => "refs#logs_tree",
          as: :logs_file,
          constraints: {
            id:   /[a-zA-Z.0-9\/_\-]+/,
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

    resources :snippets do
      member do
        get "raw"
      end
    end

    resources :hooks, only: [:index, :create, :destroy] do
      member do
        get :test
      end
    end

    resources :commit,  only: [:show], constraints: {id: /[[:alnum:]]{6,40}/}
    resources :commits, only: [:show], constraints: {id: /.+/}
    resources :compare, only: [:index, :create]
    resources :blame,   only: [:show], constraints: {id: /.+/}
    resources :blob,    only: [:show], constraints: {id: /.+/}
    resources :tree,    only: [:show, :edit, :update], constraints: {id: /.+/}
    match "/compare/:from...:to" => "compare#show", as: "compare",
                    :via => [:get, :post], constraints: {from: /.+/, to: /.+/}

    resources :team, controller: 'team_members', only: [:index]
    resources :milestones, except: [:destroy]
    resources :labels, only: [:index]
    resources :issues, except: [:destroy] do
      collection do
        post  :sort
        post  :bulk_update
        get   :search
      end
    end

    resources :team_members do
      collection do

        # Used for import team
        # from another project
        get :import
        post :apply_import
      end
    end

    resources :notes, only: [:index, :create, :destroy] do
      collection do
        post :preview
      end
    end
  end

  root to: "dashboard#index"
end
