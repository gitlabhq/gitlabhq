module Integrations
  class IssueService < BaseService

    private

    def klass
      Issue
    end

    def title(issue)
      format("##{issue.iid} #{issue.title}")
    end

    def link(issue)
      Gitlab::Routing.url_helpers.namespace_project_issue_url(project.namespace,
                                                              project,
                                                              issue)
    end
  end
end
