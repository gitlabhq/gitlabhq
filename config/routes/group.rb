# frozen_string_literal: true

# rubocop: disable Cop/PutGroupRoutesUnderScope
resources :groups, only: [:index, :new, :create] do
  post :preview_markdown
end
# rubocop: enable Cop/PutGroupRoutesUnderScope

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
      get :details, as: :details_group
      get :activity, as: :activity_group
      put :transfer, as: :transfer_group
      # TODO: Remove as part of refactor in https://gitlab.com/gitlab-org/gitlab-foss/issues/49693
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
      resource :ci_cd, only: [:show, :update], controller: 'ci_cd' do
        put :reset_registration_token
        patch :update_auto_devops
      end
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

    concerns :clusterable

    resources :group_members, only: [:index, :create, :update, :destroy], concerns: :access_requestable do
      post :resend_invite, on: :member
      delete :leave, on: :collection
    end

    resources :group_links, only: [:index, :create, :update, :destroy], constraints: { id: /\d+/ }

    resources :uploads, only: [:create] do
      collection do
        get ":secret/:filename", action: :show, as: :show, constraints: { filename: %r{[^/]+} }, format: false, defaults: { format: nil }
        post :authorize
      end
    end

    resources :boards, only: [:index, :show], constraints: { id: /\d+/ }

    resources :runners, only: [:index, :edit, :update, :destroy, :show] do
      member do
        post :resume
        post :pause
      end
    end

    resources :container_registries, only: [:index], controller: 'registry/repositories'
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
