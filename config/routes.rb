Gitlab::Application.routes.draw do

  # Optionally, enable Resque here
  require 'resque/server'
  mount Resque::Server.new, at: '/info/resque'

  get 'tags'=> 'tags#index'
  get 'tags/:tag' => 'projects#index'

  namespace :admin do
    resources :users
    resources :projects, :constraints => { :id => /[^\/]+/ }
    resources :team_members
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

  devise_for :users

  resources :projects, :constraints => { :id => /[^\/]+/ }, :except => [:new, :create, :index], :path => "/" do
    member do
      get "team"
      get "wall"
      get "graph"
      get "info"
      get "files"
    end

    resource :repository do 
      member do 
        get "branches"
        get "tags"
      end
    end

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
        get :commits
      end
    end
    
    resources :snippets
    resources :hooks, :only => [:index, :new, :create, :destroy, :show]
    resources :commits
    resources :team_members
    resources :issues do
      collection do
        post  :sort
        get   :search
      end
    end
    resources :notes, :only => [:create, :destroy]
  end
  root :to => "dashboard#index"
end
