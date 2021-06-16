# frozen_string_literal: true

# All routing related to repository browsing
# that is already under /-/ scope only

# Don't use format parameter as file extension (old 3.0.x behavior)
# See http://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments
scope format: false do
  get '/compare/:from...:to', to: 'compare#show', as: 'compare', constraints: { from: /.+/, to: /.+/ }

  resources :compare, only: [:index, :create] do
    collection do
      get :diff_for_path
      get :signatures
    end
  end

  resources :refs, only: [] do
    collection do
      get 'switch'
    end

    member do
      # tree viewer logs
      get 'logs_tree', constraints: { id: Gitlab::PathRegex.git_reference_regex }

      # Directories with leading dots erroneously get rejected if git
      # ref regex used in constraints. Regex verification now done in controller.
      get 'logs_tree/*path', action: :logs_tree, as: :logs_file, format: false, constraints: {
        id: /.*/,
        path: /[^\0]*/
      }
    end
  end

  scope constraints: { id: Gitlab::PathRegex.git_reference_regex } do
    resources :network, only: [:show]

    resources :graphs, only: [:show] do
      member do
        get :charts
        get :commits
        get :ci
        get :languages
      end
    end

    get '/branches/:state', to: 'branches#index', as: :branches_filtered, constraints: { state: /active|stale|all/ }
    resources :branches, only: [:index, :new, :create, :destroy] do
      get :diverging_commit_counts, on: :collection
    end

    delete :merged_branches, controller: 'branches', action: :destroy_all_merged
    resources :tags, only: [:index, :show, :new, :create, :destroy] do
      resource :release, controller: 'tags/releases', only: [:edit, :update]
    end

    resources :protected_branches, only: [:index, :show, :create, :update, :destroy, :patch], constraints: { id: Gitlab::PathRegex.git_reference_regex }
    resources :protected_tags, only: [:index, :show, :create, :update, :destroy]

    scope constraints: { id: /[^\0]+?/ } do
      scope controller: :static_site_editor do
        get '/sse/:id(/*vueroute)', action: :show, as: :show_sse
        get '/sse', as: :root_sse, action: :index
      end
    end
  end

  scope constraints: { id: /[^\0]+/ } do
    scope controller: :blob do
      get '/new/*id', action: :new, as: :new_blob
      post '/create/*id', action: :create, as: :create_blob
      get '/edit/*id', action: :edit, as: :edit_blob
      put '/update/*id', action: :update, as: :update_blob
      post '/preview/*id', action: :preview, as: :preview_blob

      scope path: '/blob/*id', as: :blob do
        get :diff
        get '/', action: :show
        delete '/', action: :destroy
        post '/', action: :create
        put '/', action: :update
      end
    end

    get '/tree/*id', to: 'tree#show', as: :tree
    get '/raw/*id', to: 'raw#show', as: :raw
    get '/blame/*id', to: 'blame#show', as: :blame

    get '/commits', to: 'commits#commits_root', as: :commits_root
    get '/commits/*id/signatures', to: 'commits#signatures', as: :signatures
    get '/commits/*id', to: 'commits#show', as: :commits

    post '/create_dir/*id', to: 'tree#create_dir', as: :create_dir

    scope controller: :find_file do
      get '/find_file/*id', action: :show, as: :find_file
      get '/files/*id', action: :list, as: :files
    end
  end
end

resources :commit, only: [:show], constraints: { id: /\h{7,40}/ } do
  member do
    get :branches
    get :pipelines
    post :revert
    post :cherry_pick
    get :diff_for_path
    get :diff_files
    get :merge_requests
  end
end

resource :repository, only: [:create]
