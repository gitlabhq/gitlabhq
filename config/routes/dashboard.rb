resource :dashboard, controller: 'dashboard', only: [] do
  get :issues, action: :issues_calendar, constraints: lambda { |req| req.format == :ics }
  get :issues
  get :merge_requests
  get :activity

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
        get :starred
      end
    end
  end

  root to: "dashboard/projects#index"
end
