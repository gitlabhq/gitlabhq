# frozen_string_literal: true

get :issues, to: 'issues#calendar', constraints: lambda { |req| req.format == :ics }

resources :issues, concerns: :awardable, constraints: { id: /\d+/ } do
  member do
    post :toggle_subscription
    post :mark_as_spam
    post :move
    put :reorder
    get :related_branches
    get :can_create_branch
    get :realtime_changes
    post :create_merge_request
    get :discussions, format: :json
    get '/designs(/*vueroute)', to: 'issues#designs', as: :designs, format: false
  end

  collection do
    post :bulk_update
    post :import_csv
    post :export_csv
  end
end
