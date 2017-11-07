require 'constraints/group_url_constrainer'

resources :groups, only: [:index, :new, :create] do
  post :preview_markdown
end

constraints(GroupUrlConstrainer.new) do
  scope(path: 'groups/*id',
        controller: :groups,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom)/ }) do
    get :edit, as: :edit_group
    get :issues, as: :issues_group
    get :merge_requests, as: :merge_requests_group
    get :projects, as: :projects_group
    get :activity, as: :activity_group
    get :subgroups, as: :subgroups_group
    get '/', action: :show, as: :group_canonical
  end

  scope(path: 'groups/*group_id',
        module: :groups,
        as: :group,
        constraints: { group_id: Gitlab::PathRegex.full_namespace_route_regex }) do

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

      ## EE-specific
      patch :override, on: :member
      ## EE-specific
    end

    resource :avatar, only: [:destroy]
    resources :milestones, constraints: { id: /[^\/]+/ }, only: [:index, :show, :edit, :update, :new, :create] do
      member do
        get :merge_requests
        get :participants
        get :labels
      end
    end

    ## EE-specific
    resource :notification_setting, only: [:update]
    resources :audit_events, only: [:index]
    resources :pipeline_quota, only: [:index]
    ## EE-specific

    ## EE-specific
    resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ } do
      member do
        get :test
      end
    end
    ## EE-specific

    resources :labels, except: [:show] do
      post :toggle_subscription, on: :member
    end

    scope path: '-' do
      namespace :settings do
        resource :ci_cd, only: [:show], controller: 'ci_cd'
      end

      resources :variables, only: [:index, :show, :update, :create, :destroy]

      resources :children, only: [:index]

      ## EE-specific
      resources :billings, only: [:index]
      resources :boards, only: [:index, :show, :create, :update, :destroy]
      resources :epics do
        member do
          get :realtime_changes
        end
      end
    end

    ## EE-specific
    legacy_ee_group_boards_redirect = redirect do |params, request|
      path = "/groups/#{params[:group_id]}/-/boards"
      path << "/#{params[:extra_params]}" if params[:extra_params].present?
      path << "?#{request.query_string}" if request.query_string.present?
      path
    end

    get 'boards(/*extra_params)', as: :legacy_ee_group_boards_redirect, to: legacy_ee_group_boards_redirect
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
end
