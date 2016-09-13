module Integrations
  class IssueService < BaseService

    private

    def klass
      Issue
    end

    def title(issue)
      "[##{issue.iid} #{issue.title}](#{link(issue)})"
    end

    def link(issue)
      Gitlab::Routing.url_helpers.namespace_project_issue_url(project.namespace,
                                                              project,
                                                              issue)
    end

    def find_resource
      collection.find_by(iid: params[:text])
    end
  end
end
