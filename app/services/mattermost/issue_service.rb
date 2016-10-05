module Mattermost
  class IssueService < BaseService
    private

    def collection
      project.issues
    end

    def link(issue)
      Gitlab::Routing.
        url_helpers.
        namespace_project_issue_url(project.namespace, project, issue)
    end
  end
end
