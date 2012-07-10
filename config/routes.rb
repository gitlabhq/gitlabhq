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
  mount Resque::Server.new, at: '/info/resque'

  # Enable Grack support
  mount Grack::Bundle.new({
    git_path:     Gitlab.config.git_bin_path,
    project_root: Gitlab.config.git_base_path,
    upload_pack:  Gitlab.config.git_upload_pack,
    receive_pack: Gitlab.config.git_receive_pack
  }), at: '/:path', constraints: { path: /[\w-]+\.git/ }

  #
  # Help
  #
  get 'help' => 'help#index'
  get 'help/permissions' => 'help#permissions'
  get 'help/workflow' => 'help#workflow'
  get 'help/api' => 'help#api'
  get 'help/web_hooks' => 'help#web_hooks'

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
    resources :projects, :constraints => { :id => /[^\/]+/ } do
      member do
        get :team
        put :team_update
      end
    end
    resources :team_members, :only => [:edit, :update, :destroy]
    get 'emails', :to => 'mailer#preview'
    get 'mailer/preview_note'
    get 'mailer/preview_user_new'
    get 'mailer/preview_issue_new'

    resource :logs
    resource :resque, :controller => 'resque'
    root :to => "dashboard#index"
  end

  get "errors/githost"

  #
  # Profile Area
  #
  get "profile/password", :to => "profile#password"
  put "profile/password", :to => "profile#password_update"
  get "profile/token", :to => "profile#token"
  put "profile/reset_private_token", :to => "profile#reset_private_token"
  get "profile", :to => "profile#show"
  get "profile/design", :to => "profile#design"
  put "profile/update", :to => "profile#update"
  resources :keys

  #
  # Dashboard Area
  #
  get "dashboard", :to => "dashboard#index"
  get "dashboard/issues", :to => "dashboard#issues"
  get "dashboard/merge_requests", :to => "dashboard#merge_requests"

  resources :projects, :constraints => { :id => /[^\/]+/ }, :only => [:new, :create]

  devise_for :users, :controllers => { :omniauth_callbacks => :omniauth_callbacks }

  #
  # Project Area
  #
  resources :projects, :constraints => { :id => /[^\/]+/ }, :except => [:new, :create, :index], :path => "/" do
    member do
      get "team"
      get "wall"
      get "graph"
      get "files"
    end

    resources :wikis, :only => [:show, :edit, :destroy, :create] do
      member do
        get "history"
      end
    end

    resource :repository do
      member do
        get "branches"
        get "tags"
        get "archive"
      end
    end

    resources :deploy_keys
    resources :protected_branches, :only => [:index, :create, :destroy]

    resources :refs, :only => [], :path => "/" do
      collection do
        get "switch"
      end

      member do
        get "tree", :constraints => { :id => /[a-zA-Z.\/0-9_\-]+/ }
        get "logs_tree", :constraints => { :id => /[a-zA-Z.\/0-9_\-]+/ }

        get "blob",
          :constraints => {
            :id => /[a-zA-Z.0-9\/_\-]+/,
            :path => /.*/
          }


        # tree viewer
        get "tree/:path" => "refs#tree",
          :as => :tree_file,
          :constraints => {
            :id => /[a-zA-Z.0-9\/_\-]+/,
            :path => /.*/
          }

        # tree viewer
        get "logs_tree/:path" => "refs#logs_tree",
          :as => :logs_file,
          :constraints => {
            :id => /[a-zA-Z.0-9\/_\-]+/,
            :path => /.*/
          }

        # blame
        get "blame/:path" => "refs#blame",
          :as => :blame_file,
          :constraints => {
            :id => /[a-zA-Z.0-9\/_\-]+/,
            :path => /.*/
          }
      end
    end

    resources :merge_requests do
      member do
        get :diffs
        get :automerge
        get :automerge_check
        get :raw
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

    resources :hooks, :only => [:index, :create, :destroy] do
      member do
        get :test
      end
    end
    resources :commits do
      collection do
        get :compare
      end

      member do
        get :patch
      end
    end
    resources :team_members
    resources :milestones
    resources :issues do
      collection do
        post  :sort
        get   :search
      end
    end
    resources :notes, :only => [:index, :create, :destroy]
  end
  root :to => "dashboard#index"
end
