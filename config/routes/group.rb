# frozen_string_literal: true

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(
    path: 'groups/*id',
    controller: :groups,
    constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom|ics)/ }
  ) do
    scope(path: '-') do
      # rubocop:disable Cop/PutGroupRoutesUnderScope -- These routes are legit and the cop rule will be improved in https://gitlab.com/gitlab-org/gitlab/-/issues/230703
      get :edit, as: :edit_group
      get :issues, as: :issues_group_calendar, action: :issues_calendar, constraints: ->(req) { req.format == :ics }
      get :issues, as: :issues_group
      get :merge_requests, as: :merge_requests_group
      get :details, as: :details_group
      get :activity, as: :activity_group
      put :transfer, as: :transfer_group
      post :export, as: :export_group
      get :download_export, as: :download_export_group
      get :unfoldered_environment_names, as: :unfoldered_environment_names_group

      get 'shared', action: :show, as: :group_shared
      get 'shared_groups', action: :show, as: :group_shared_groups
      get 'inactive', action: :show, as: :group_inactive
      get 'archived', to: redirect('groups/%{id}/-/inactive')
      # rubocop:enable Cop/PutGroupRoutesUnderScope
    end

    get '/', action: :show, as: :group_canonical
    delete '/', action: :destroy, as: :destroy_group_canonical
  end

  scope(
    path: 'groups/*group_id/-',
    module: :groups,
    as: :group,
    constraints: { group_id: Gitlab::PathRegex.full_namespace_route_regex }
  ) do
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

      resources :access_tokens, only: [:index, :create] do
        member do
          put :revoke
          put :rotate
        end

        collection do
          get :inactive, format: :json
        end
      end

      resources :integrations, only: [:index, :edit, :update] do
        member do
          put :test
          post :reset
        end
      end

      resource :slack, only: [:destroy] do
        get :slack_auth
      end

      resources :applications do
        put 'renew', on: :member
      end

      resource :packages_and_registries, only: [:show]
    end

    resource :usage_quotas do
      get '/', to: 'usage_quotas#root'
    end

    resource :variables, only: [:show, :update]

    resources :children, only: [:index]
    resources :shared_projects, only: [:index]

    resources :labels, except: [:show] do
      post :toggle_subscription, on: :member
    end

    resources :custom_emoji, only: [:index, :new], action: :index

    resources :packages, only: [:index, :show]

    resources :terraform_module_registry, only: [:index], as: :infrastructure_registry, controller: 'infrastructure_registry'
    get :infrastructure_registry, to: redirect('groups/%{group_id}/-/terraform_module_registry')

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

    resources :group_members, only: [:index, :update, :destroy], concerns: :access_requestable do
      post :resend_invite, on: :member

      collection do
        resource :bulk_reassignment_file, only: %i[show create], controller: 'bulk_placeholder_assignments' do
          post :authorize
        end

        delete :leave

        get :invite_search, format: :json
      end
    end

    resources :group_links, only: [:update, :destroy], constraints: { id: /\d+|:id/ }

    resources :uploads, only: [:create] do
      collection do
        get ":secret/:filename", action: :show, as: :show, constraints: { filename: %r{[^/]+} }, format: false, defaults: { format: nil }
        post :authorize
      end
    end

    resources :boards, only: [:index, :show], constraints: { id: /\d+/ }

    resources :runners, only: [:index, :new, :edit, :update, :destroy, :show] do
      member do
        get :register
        post :resume
        post :pause
      end
    end

    resources :container_registries, only: [:index, :show], controller: 'registry/repositories'
    resource :dependency_proxy, only: [:show, :update]

    namespace :harbor do
      resources :repositories, only: [:index, :show], constraints: { id: %r{[a-zA-Z./:0-9_\-]+} } do
        resources :artifacts, only: [:index] do
          resources :tags, only: [:index]
        end
      end
    end

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

    namespace :crm do
      resources :contacts, only: [:index, :new, :edit]
      resources :organizations, only: [:index, :new, :edit]
    end

    resources :achievements, only: [:index, :new, :edit]

    resources :work_items, only: [:index, :show], param: :iid

    resource :import_history, only: [:show]

    resources :observability, only: [:show]

    post :preview_markdown

    post '/restore' => '/groups#restore', as: :restore
  end

  scope(
    path: '*id',
    as: :group,
    constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom)/ },
    controller: :groups
  ) do
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
    post 'v2/*group_id/dependency_proxy/containers/*image/blobs/:sha/upload/authorize' => 'groups/dependency_proxy_for_containers#authorize_upload_blob' # rubocop:todo Cop/PutGroupRoutesUnderScope
    post 'v2/*group_id/dependency_proxy/containers/*image/blobs/:sha/upload' => 'groups/dependency_proxy_for_containers#upload_blob' # rubocop:todo Cop/PutGroupRoutesUnderScope
    post 'v2/*group_id/dependency_proxy/containers/*image/manifests/*tag/upload/authorize' => 'groups/dependency_proxy_for_containers#authorize_upload_manifest' # rubocop:todo Cop/PutGroupRoutesUnderScope
    post 'v2/*group_id/dependency_proxy/containers/*image/manifests/*tag/upload' => 'groups/dependency_proxy_for_containers#upload_manifest' # rubocop:todo Cop/PutGroupRoutesUnderScope
  end
end
