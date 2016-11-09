require 'constraints/group_url_constrainer'

constraints(GroupUrlConstrainer.new) do
  scope(path: ':id',
        as: :group,
        constraints: { id: Gitlab::Regex.namespace_route_regex },
        controller: :groups) do
    get '/', action: :show
    patch '/', action: :update
    put '/', action: :update
    delete '/', action: :destroy
  end
end

resources :groups, only: [:index, :new, :create]

scope(path: 'groups/:id', controller: :groups) do
  get :edit, as: :edit_group
  get :issues, as: :issues_group
  get :merge_requests, as: :merge_requests_group
  get :projects, as: :projects_group
  get :activity, as: :activity_group
end

scope(path: 'groups/:group_id', module: :groups, as: :group) do
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

  ## EE-specific
  resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ } do
    member do
      get :test
    end
  end
  ## EE-specific
end

# Must be last route in this file
get 'groups/:id' => 'groups#show', as: :group_canonical
