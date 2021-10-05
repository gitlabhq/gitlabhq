# frozen_string_literal: true

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(path: 'groups/*id',
        controller: :groups,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom|ics)/ }) do
    scope(path: '-') do
      # These routes are legit and the cop rule will be improved in
      # https://gitlab.com/gitlab-org/gitlab/-/issues/230703
      get :edit, as: :edit_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      get :issues, as: :issues_group_calendar, action: :issues_calendar, constraints: lambda { |req| req.format == :ics } # rubocop:disable Cop/PutGroupRoutesUnderScope
      get :issues, as: :issues_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      get :merge_requests, as: :merge_requests_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      get :projects, as: :projects_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      get :details, as: :details_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      get :activity, as: :activity_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      put :transfer, as: :transfer_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      post :export, as: :export_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      get :download_export, as: :download_export_group # rubocop:disable Cop/PutGroupRoutesUnderScope
      get :unfoldered_environment_names, as: :unfoldered_environment_names_group # rubocop:disable Cop/PutGroupRoutesUnderScope

      # TODO: Remove as part of refactor in https://gitlab.com/gitlab-org/gitlab-foss/issues/49693
      get 'shared', action: :show, as: :group_shared # rubocop:disable Cop/PutGroupRoutesUnderScope
      get 'archived', action: :show, as: :group_archived # rubocop:disable Cop/PutGroupRoutesUnderScope
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
        post :create_deploy_token, path: 'deploy_token/create', to: 'repository#create_deploy_token'
        get :runner_setup_scripts, format: :json
      end

      resource :repository, only: [:show], controller: 'repository' do
        post :create_deploy_token, path: 'deploy_token/create'
      end

      resources :integrations, only: [:index, :edit, :update] do
        member do
          put :test
          post :reset
        end
      end

      resources :applications

      resource :packages_and_registries, only: [:show]
    end

    resource :variables, only: [:show, :update]

    resources :children, only: [:index]
    resources :shared_projects, only: [:index]

    resources :labels, except: [:show] do
      post :toggle_subscription, on: :member
    end

    resources :packages, only: [:index]

    resources :milestones, constraints: { id: %r{[^/]+} } do
      member do
        get :issues
        get :merge_requests
        get :participants
        get :labels
      end
    end

    resources :releases, only: [:index]

    resources :deploy_tokens, constraints: { id: /\d+/ }, only: [] do
      member do
        put :revoke
      end
    end

    resource :avatar, only: [:destroy]
    resource :import, only: [:show]

    concerns :clusterable

    resources :group_members, only: [:index, :create, :update, :destroy], concerns: :access_requestable do
      post :resend_invite, on: :member
      delete :leave, on: :collection
    end

    resources :group_links, only: [:create, :update, :destroy], constraints: { id: /\d+|:id/ }

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

    resources :container_registries, only: [:index, :show], controller: 'registry/repositories'
    resource :dependency_proxy, only: [:show, :update]
    resources :email_campaigns, only: :index

    resources :autocomplete_sources, only: [] do
      collection do
        get 'members'
        get 'issues'
        get 'merge_requests'
        get 'labels'
        get 'commands'
        get 'milestones'
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
end

# Dependency proxy for containers
# Because docker adds v2 prefix to URI this need to be outside of usual group routes
scope format: false do
  get 'v2' => 'groups/dependency_proxy_auth#authenticate' # rubocop:disable Cop/PutGroupRoutesUnderScope

  constraints image: Gitlab::PathRegex.container_image_regex, sha: Gitlab::PathRegex.container_image_blob_sha_regex do
    get 'v2/*group_id/dependency_proxy/containers/*image/manifests/*tag' => 'groups/dependency_proxy_for_containers#manifest' # rubocop:todo Cop/PutGroupRoutesUnderScope
    get 'v2/*group_id/dependency_proxy/containers/*image/blobs/:sha' => 'groups/dependency_proxy_for_containers#blob' # rubocop:todo Cop/PutGroupRoutesUnderScope
  end
end
