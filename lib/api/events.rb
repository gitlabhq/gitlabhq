# frozen_string_literal: true

module API
  class Events < Grape::API
    include PaginationParams
    include APIGuard

    helpers do
      params :event_filter_params do
        optional :action, type: String, values: Event.actions, desc: 'Event action to filter on'
        optional :target_type, type: String, values: Event.target_types, desc: 'Event target type to filter on'
        optional :before, type: Date, desc: 'Include only events created before this date'
        optional :after, type: Date, desc: 'Include only events created after this date'
      end

      params :sort_params do
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return events sorted in ascending and descending order'
      end

      def present_events(events)
        events = paginate(events)

        present events, with: Entities::Event
      end

      def find_events(source)
        EventsFinder.new(params.merge(source: source, current_user: current_user, with_associations: true)).execute
      end
    end

    resource :events do
      allow_access_with_scope :read_user, if: -> (request) { request.get? }

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
      allow_access_with_scope :read_user, if: -> (request) { request.get? }

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

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "List a Project's visible events" do
        success Entities::Event
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end

      get ":id/events" do
        events = find_events(user_project)

        present_events(events)
      end
    end
  end
end
