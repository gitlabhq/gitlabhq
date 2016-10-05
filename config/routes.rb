require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'api/api'

class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
end

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

  concern :awardable do
    post :toggle_award_emoji, on: :member
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

  # Koding route
  get 'koding' => 'koding#index'

  # Global snippets
  resources :snippets, concerns: :awardable do
    member do
      get 'raw'
    end
  end

  get '/s/:username', to: redirect('/u/%{username}/snippets'),
                      constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }

  # Invites
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

  # Notification settings
  resources :notification_settings, only: [:create, :update]

  draw :import
  draw :uploads
  draw :explore
  draw :admin
  draw :profile
  draw :dashboard
  draw :group
  draw :user
  draw :project

  get ':id' => 'namespaces#show', constraints: { id: /(?:[^.]|\.(?!atom$))+/, format: /atom/ }

  root to: "root#index"
end
