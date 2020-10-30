# frozen_string_literal: true

module API
  class ProjectEvents < ::API::Base
    include PaginationParams
    include APIGuard
    helpers ::API::Helpers::EventsHelpers

    feature_category :users

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
