# frozen_string_literal: true

module API
  class ProjectEvents < ::API::Base
    include PaginationParams
    include APIGuard
    helpers ::API::Helpers::EventsHelpers

    feature_category :user_profile

    # TODO: Set higher urgency after resolving https://gitlab.com/gitlab-org/gitlab/-/issues/357839
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      optional :action, type: String, desc: 'Include only events of a particular action type'
      optional :target_type, type: String, desc: 'Include only events of a particular target type'
      optional :before, type: DateTime, desc: 'Include only events created before a particular date'
      optional :after, type: DateTime, desc: 'Include only events created after a particular date'
      optional :sort, type: String, desc: 'Sort events in asc or desc order by created_at. Default is desc'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "List a project's visible events" do
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
