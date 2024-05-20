# frozen_string_literal: true

module API
  class Events < ::API::Base
    include PaginationParams
    include APIGuard
    helpers ::API::Helpers::EventsHelpers

    allow_access_with_scope :read_user, if: ->(request) { request.get? || request.head? }

    feature_category :user_profile
    urgency :low

    resource :events do
      desc "List currently authenticated user's events" do
        detail 'This feature was introduced in GitLab 9.3.'
        success Entities::Event
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
      end
      params do
        optional :scope, type: String,
          desc: 'Include all events across a user’s projects',
          documentation: { example: 'all' }
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
      requires :id, type: String, desc: 'The ID or username of the user'
    end
    resource :users do
      desc 'Get the contribution events of a specified user' do
        detail 'This feature was introduced in GitLab 8.13.'
        success Entities::Event
        tags %w[events]
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
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
