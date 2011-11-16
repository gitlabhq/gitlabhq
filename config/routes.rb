Gitlab::Application.routes.draw do

  get 'tags'=> 'tags#index'
  get 'tags/:tag' => 'projects#index'

  namespace :admin do
    resources :users
    resources :projects
    resources :team_members
    get 'emails', :to => 'mailer#preview'
    get 'mailer/preview_note'
    get 'mailer/preview_user_new'
    get 'mailer/preview_issue_new'
    root :to => "users#index"
  end

  get "errors/gitosis"
  get "profile/password", :to => "profile#password"
  put "profile/password", :to => "profile#password_update"
  put "profile/reset_private_token", :to => "profile#reset_private_token"
  put "profile/edit", :to => "profile#social_update"
  get "profile", :to => "profile#show"
  get "dashboard", :to => "dashboard#index"
  #get "profile/:id", :to => "profile#show"

  resources :projects, :only => [:new, :create, :index]
  resources :keys

  devise_for :users

  resources :projects, :except => [:new, :create, :index], :path => "/" do
    member do
      get "team"
      get "wall"
      get "graph"
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

    resources :snippets
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
