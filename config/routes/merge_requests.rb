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
    get :accessibility_reports
    get :coverage_reports
    get :terraform_reports

    # documented in doc/development/rails_endpoints/index.md
    get :codequality_reports
    # documented in doc/development/rails_endpoints/index.md
    get :codequality_mr_diff_reports

    scope constraints: ->(req) { req.format == :json }, as: :json do
      get :commits
      get :pipelines
      get :context_commits
      get :diffs, to: 'merge_requests/diffs#show'
      get :diffs_batch, to: 'merge_requests/diffs#diffs_batch'
      get :diffs_metadata, to: 'merge_requests/diffs#diffs_metadata'
      get :widget, to: 'merge_requests/content#widget'
      get :cached_widget, to: 'merge_requests/content#cached_widget'
    end

    scope action: :show do
      get :commits, defaults: { tab: 'commits' }
      get :pipelines, defaults: { tab: 'pipelines' }
      get :diffs, to: 'merge_requests#rapid_diffs', defaults: { tab: 'diffs' },
        constraints: ->(params) { params[:rapid_diffs] == 'true' }
      get :diffs, to: 'merge_requests#diffs', defaults: { tab: 'diffs' }
    end

    get :diff_for_path, controller: 'merge_requests/diffs'
    get 'diff_by_file_hash/:file_hash', to: 'merge_requests/diffs#diff_by_file_hash', as: :diff_by_file_hash
    get :diffs_stream, to: 'merge_requests/diffs_stream#diffs'

    # NOTE: Fallback to `merge_requests/diffs#diff_for_path` to handle `collapsed_diff_url` from the collapsed partial
    scope controller: 'merge_requests/diffs_stream' do
      get :diff_for_path
    end

    scope controller: 'merge_requests/conflicts' do
      get :conflicts, action: :show
      get :conflict_for_path
      post :resolve_conflicts
    end
  end

  collection do
    get :diff_for_path
    post :bulk_update
    post :export_csv
  end

  scope module: :merge_requests do
    resources :drafts, only: [:index, :update, :create, :destroy] do
      collection do
        post :publish
        delete :discard
      end
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
      get :target_projects
    end

    scope action: :new do
      get :diffs, defaults: { tab: 'diffs' }
      get :pipelines, defaults: { tab: 'pipelines' }
    end

    get :diff_for_path
    get :branch_from
    get :branch_to
    get :diffs_stream, to: 'merge_requests/creations_diffs_stream#diffs'
  end
end
