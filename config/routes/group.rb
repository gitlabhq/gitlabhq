resources :groups, only: [:index, :new, :create] do
  post :preview_markdown
end

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(path: 'groups/*id',
        controller: :groups,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom|ics)/ }) do
    scope(path: '-') do
      get :edit, as: :edit_group
      get :issues, as: :issues_group_calendar, action: :issues_calendar, constraints: lambda { |req| req.format == :ics }
      get :issues, as: :issues_group
      get :merge_requests, as: :merge_requests_group
      get :projects, as: :projects_group
      get :activity, as: :activity_group
      put :transfer, as: :transfer_group
      # TODO: Remove as part of refactor in https://gitlab.com/gitlab-org/gitlab-ce/issues/49693
      get 'shared', action: :show, as: :group_shared
      get 'archived', action: :show, as: :group_archived
    end

    get '/', action: :show, as: :group_canonical
  end

  scope(path: 'groups/*group_id/-',
        module: :groups,
        as: :group,
        constraints: { group_id: Gitlab::PathRegex.full_namespace_route_regex }) do
    namespace :settings do
      resource :ci_cd, only: [:show], controller: 'ci_cd'
    end

    resource :variables, only: [:show, :update]

    resources :children, only: [:index]
    resources :shared_projects, only: [:index]

    resources :labels, except: [:show] do
      post :toggle_subscription, on: :member
    end

    resources :milestones, constraints: { id: %r{[^/]+} } do
      member do
        get :merge_requests
        get :participants
        get :labels
      end
    end

    resource :avatar, only: [:destroy]

    resources :group_members, only: [:index, :create, :update, :destroy], concerns: :access_requestable do
      post :resend_invite, on: :member
      delete :leave, on: :collection
    end

    resources :uploads, only: [:create] do
      collection do
        get ":secret/:filename", action: :show, as: :show, constraints: { filename: %r{[^/]+} }
        post :authorize
      end
    end

    # On CE only index and show actions are needed
    resources :boards, only: [:index, :show]

    resources :runners, only: [:index, :edit, :update, :destroy, :show] do
      member do
        post :resume
        post :pause
      end
    end
  end

  scope(path: '*id',
        as: :group,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom)/ },
        controller: :groups) do
    get '/', action: :show
    patch '/', action: :update
    put '/', action: :update
    delete '/', action: :destroy
  end

  # Legacy paths should be defined last, so they would be ignored if routes with
  # one of the previously reserved words exist.
  scope(path: 'groups/*group_id') do
    Gitlab::Routing.redirect_legacy_paths(self, :labels, :milestones, :group_members,
                                          :edit, :issues, :merge_requests, :projects,
                                          :activity)
  end
end
