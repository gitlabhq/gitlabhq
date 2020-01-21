# frozen_string_literal: true
resources :merge_requests, concerns: :awardable, except: [:new, :create, :show], constraints: { id: /\d+/ } do
  member do
    get :show # Insert this first to ensure redirections using merge_requests#show match this route
    get :commit_change_content
    post :merge
    post :cancel_auto_merge
    get :pipeline_status
    get :ci_environments_status
    post :toggle_subscription
    post :remove_wip
    post :assign_related_issues
    get :discussions, format: :json
    post :rebase
    get :test_reports
    get :exposed_artifacts

    scope constraints: ->(req) { req.format == :json }, as: :json do
      get :commits
      get :pipelines
      get :diffs, to: 'merge_requests/diffs#show'
      get :diffs_batch, to: 'merge_requests/diffs#diffs_batch'
      get :diffs_metadata, to: 'merge_requests/diffs#diffs_metadata'
      get :widget, to: 'merge_requests/content#widget'
      get :cached_widget, to: 'merge_requests/content#cached_widget'
    end

    scope action: :show do
      get :commits, defaults: { tab: 'commits' }
      get :pipelines, defaults: { tab: 'pipelines' }
      get :diffs, defaults: { tab: 'diffs' }
    end

    get :diff_for_path, controller: 'merge_requests/diffs'

    scope controller: 'merge_requests/conflicts' do
      get :conflicts, action: :show
      get :conflict_for_path
      post :resolve_conflicts
    end
  end

  collection do
    get :diff_for_path
    post :bulk_update
  end

  resources :discussions, only: [:show], constraints: { id: /\h{40}/ } do
    member do
      post :resolve
      delete :resolve, action: :unresolve
    end
  end
end

scope path: 'merge_requests', controller: 'merge_requests/creations' do
  post '', action: :create, as: nil

  scope path: 'new', as: :new_merge_request do
    get '', action: :new

    scope constraints: ->(req) { req.format == :json }, as: :json do
      get :diffs
      get :pipelines
    end

    scope action: :new do
      get :diffs, defaults: { tab: 'diffs' }
      get :pipelines, defaults: { tab: 'pipelines' }
    end

    get :diff_for_path
    get :branch_from
    get :branch_to
  end
end
