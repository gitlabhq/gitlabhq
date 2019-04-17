# frozen_string_literal: true

module API
  class Events < Grape::API
    include PaginationParams
    include APIGuard
    helpers ::API::Helpers::EventsHelpers

    allow_access_with_scope :read_user, if: -> (request) { request.get? }

    resource :events do
      desc "List currently authenticated user's events" do
        detail 'This feature was introduced in GitLab 9.3.'
        success Entities::Event
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end

      get do
        authenticate!

        events = find_events(current_user)

        present_events(events)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID or Username of the user'
    end
    resource :users do
      desc 'Get the contribution events of a specified user' do
        detail 'This feature was introduced in GitLab 8.13.'
        success Entities::Event
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end

      get ':id/events' do
        user = find_user(params[:id])
        not_found!('User') unless user

        events = find_events(user)

        present_events(events)
      end
    end
  end
end
