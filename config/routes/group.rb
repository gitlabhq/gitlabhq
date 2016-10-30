require 'constraints/group_url_constrainer'

constraints(GroupUrlConstrainer.new) do
  scope(path: ':id',
        as: :group,
        constraints: { id: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ },
        controller: :groups) do
    get '/', action: :show
    patch '/', action: :update
    put '/', action: :update
    delete '/', action: :destroy
  end
end

scope constraints: { id: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ } do
  resources :groups, except: [:show] do
    member do
      get :issues
      get :merge_requests
      get :projects
      get :activity
    end

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
      resources :labels, except: [:show], constraints: { id: /\d+/ }

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

  get 'groups/:id' => 'groups#show', as: :group_canonical
end
