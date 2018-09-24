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

      # rubocop: disable CodeReuse/ActiveRecord
      def present_events(events)
        events = events.reorder(created_at: params[:sort])
                 .with_associations

        present paginate(events), with: Entities::Event
      end
      # rubocop: enable CodeReuse/ActiveRecord
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
      # rubocop: disable CodeReuse/ActiveRecord
      get do
        authenticate!

        events = EventsFinder.new(params.merge(source: current_user, current_user: current_user)).execute.preload(:author, :target)

        present_events(events)
      end
      # rubocop: enable CodeReuse/ActiveRecord
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
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/events' do
        user = find_user(params[:id])
        not_found!('User') unless user

        events = EventsFinder.new(params.merge(source: user, current_user: current_user)).execute.preload(:author, :target)

        present_events(events)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc "List a Project's visible events" do
        success Entities::Event
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ":id/events" do
        events = EventsFinder.new(params.merge(source: user_project, current_user: current_user)).execute.preload(:author, :target)

        present_events(events)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
