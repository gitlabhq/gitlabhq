Gitlab::Application.routes.draw do


  # Optionally, enable Resque here
  require 'resque/server'
  mount Resque::Server.new, at: '/info/resque'

  get 'help' => 'help#index'
  get 'help/permissions' => 'help#permissions'
  get 'help/workflow' => 'help#workflow'

  namespace :admin do
    resources :users do 
      member do 
        put :team_update
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
    root :to => "users#index"
  end

  get "errors/githost"
  get "profile/password", :to => "profile#password"
  put "profile/password", :to => "profile#password_update"
  put "profile/reset_private_token", :to => "profile#reset_private_token"
  get "profile", :to => "profile#show"
  get "profile/design", :to => "profile#design"
  put "profile/update", :to => "profile#update"

  get "dashboard", :to => "dashboard#index"
  get "dashboard/issues", :to => "dashboard#issues"
  get "dashboard/merge_requests", :to => "dashboard#merge_requests"

  #get "profile/:id", :to => "profile#show"

  resources :projects, :constraints => { :id => /[^\/]+/ }, :only => [:new, :create, :index]
  resources :keys

  devise_for :users, :controllers => { :omniauth_callbacks => :omniauth_callbacks }

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
      end
    end

    resources :merge_requests do 
      member do 
        get :diffs
      end
    end
    
    resources :snippets
    resources :hooks, :only => [:index, :new, :create, :destroy, :show] do 
      member do 
        get :test
      end
    end
    resources :commits do 
      collection do 
        get :compare
      end
    end
    resources :team_members
    resources :issues do
      collection do
        post  :sort
        get   :search
      end
    end
    resources :notes, :only => [:create, :destroy]
  end
  root :to => "projects#index"
end
