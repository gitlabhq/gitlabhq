# frozen_string_literal: true

resources :pipelines, only: [:index, :new, :create, :show, :destroy] do
  collection do
    resource :pipelines_settings, path: 'settings', only: [:show, :update]
    get :charts
    scope '(*ref)', constraints: { ref: Gitlab::PathRegex.git_reference_regex } do
      get :latest, action: :show, defaults: { latest: true }
    end
  end

  member do
    get :stage
    get :stage_ajax
    post :cancel
    post :retry
    get :builds
    get :failures
    get :status
    get :test_report
    get :test_reports_count
  end

  member do
    resources :stages, only: [], param: :name do
      post :play_manual
    end
  end
end

resources :pipeline_schedules, except: [:show] do
  member do
    post :play
    post :take_ownership
  end
end
