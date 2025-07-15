# frozen_string_literal: true

resource :dashboard, controller: 'dashboard', only: [] do
  get :home
  get :issues, action: :issues_calendar, constraints: ->(req) { req.format == :ics }
  get :issues
  get :merge_requests
  get :activity
  get 'merge_requests/following', to: 'dashboard#merge_requests'
  get 'merge_requests/search', to: 'dashboard#search_merge_requests'
  get 'merge_requests/merged', to: 'dashboard#merge_requests'

  scope module: :dashboard do
    resources :milestones, only: [:index]
    resources :labels, only: [:index]

    resources :groups, only: [:index] do
      collection do
        get :member, :inactive, to: 'groups#index'
      end
    end
    resources :snippets, only: [:index]

    resources :todos, only: [:index, :destroy]

    resources :projects, only: [:index] do
      collection do
        get :contributed, :starred, :personal, :member, :inactive, to: 'projects#index'
      end
    end
  end

  root to: "dashboard/projects#index"
end
