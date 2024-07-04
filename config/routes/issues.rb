# frozen_string_literal: true

get :issues, to: 'issues#calendar', constraints: ->(req) { req.format == :ics }

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
    get '/:incident_tab',
      action: :show,
      as: :incident_issue,
      constraints: { incident_tab: /timeline|metrics|alerts/ }
  end

  collection do
    get :service_desk
    post :bulk_update
    post :import_csv
    post :export_csv

    scope :incident do
      get '/:id(/:incident_tab)',
        to: 'incidents#show',
        as: :incident,
        constraints: { incident_tab: /timeline|metrics|alerts/ }
    end
  end

  resources :issue_links, only: [:index, :create, :destroy], as: 'links', path: 'links'
end
