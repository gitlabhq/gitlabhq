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

resources :groups, constraints: { id: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }  do
  member do
    get :issues
    get :merge_requests
    get :projects
    get :activity
  end

  scope module: :groups do
    resources :group_members, only: [:index, :create, :update, :destroy], concerns: :access_requestable do
      post :resend_invite, on: :member
      delete :leave, on: :collection
    end

    resource :avatar, only: [:destroy]
    resources :milestones, constraints: { id: /[^\/]+/ }, only: [:index, :show, :update, :new, :create]
  end
end
