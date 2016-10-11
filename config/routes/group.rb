require 'constraints/group_url_constrainer'

constraints(GroupUrlConstrainer.new) do
  scope(path: ':id', as: :group, controller: :groups) do
    get '/', action: :show
  end
end

resources :groups, constraints: { id: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }  do
  member do
    get :issues
    get :merge_requests
    get :projects
    get :activity
  end

  ## EE-specific
  collection do
    get :autocomplete
  end
  ## EE-specific

  scope module: :groups do
    ## EE-specific
    resource :analytics, only: [:show]
    resource :ldap, only: [] do
      member do
        put :sync
      end
    end

    resources :ldap_group_links, only: [:index, :create, :destroy]
    ## EE-specific

    resources :group_members, only: [:index, :create, :update, :destroy], concerns: :access_requestable do
      post :resend_invite, on: :member
      delete :leave, on: :collection
    end

    resource :avatar, only: [:destroy]
    resources :milestones, constraints: { id: /[^\/]+/ }, only: [:index, :show, :update, :new, :create]

    ## EE-specific
    resource :notification_setting, only: [:update]
    resources :audit_events, only: [:index]
    ## EE-specific
  end

  ## EE-specific
  resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ }, module: :groups do
    member do
      get :test
    end
  end
  ## EE-specific
end
