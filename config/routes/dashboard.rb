# frozen_string_literal: true

resource :dashboard, controller: 'dashboard', only: [] do
  get :issues, action: :issues_calendar, constraints: ->(req) { req.format == :ics }
  get :issues
  get :merge_requests
  get :activity
  get 'merge_requests/search', to: 'dashboard#merge_requests'

  scope module: :dashboard do
    resources :milestones, only: [:index]
    resources :labels, only: [:index]

    resources :groups, only: [:index]
    resources :snippets, only: [:index]

    resources :todos, only: [:index, :destroy] do
      collection do
        delete :destroy_all
        patch :bulk_restore
      end
      member do
        patch :restore
      end
    end

    resources :projects, only: [:index] do
      collection do
        ## TODO: Migrate this over to to: 'projects#index' as part of `:your_work_projects_vue` FF rollout
        ## https://gitlab.com/gitlab-org/gitlab/-/issues/465889
        get :starred
        get :contributed, to: 'projects#index'
        get :personal, to: 'projects#index'
        get :member, to: 'projects#index'
      end
    end
  end

  root to: "dashboard/projects#index"
end
