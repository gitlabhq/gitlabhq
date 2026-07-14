# frozen_string_literal: true

module API
  class ProjectEvents < ::API::Base
    include PaginationParams
    include APIGuard

    helpers ::API::Helpers::EventsHelpers

    before { set_current_organization }

    feature_category :groups_and_projects

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
      desc 'List all visible events for a project' do
        detail 'Lists all visible events for a specified project. When a push exceeds the Push event ' \
          'activities limit, a single bulk push event is returned instead of individual commit events. ' \
          'Bulk push events have limited commit details: `commit_count` is `0`, `ref_count` shows the ' \
          'number of refs pushed, and individual commit attributes are `null`.'
        success Entities::Event
        tags ['events']
      end
      params do
        use :pagination
        use :event_filter_params
        use :sort_params
      end

      route_setting :authorization, permissions: :read_event, boundary_type: :project
      get ":id/events" do
        events = find_events(user_project)

        present_events(events)
      end
    end
  end
end
