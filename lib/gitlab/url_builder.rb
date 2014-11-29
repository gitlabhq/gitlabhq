module Gitlab
  class UrlBuilder
    include Rails.application.routes.url_helpers

    def initialize(type)
      @type = type
    end

    def build(id)
      case @type
      when :issue
        issue_url(id)
      when :merge_request
        merge_request_url(id)
      end
    end

    private

    def issue_url(id)
      issue = Issue.find(id)
      project_issue_url(id: issue.iid,
                        project_id: issue.project,
                        host: Gitlab.config.gitlab['url'])
    end

    def merge_request_url(id)
      merge_request = MergeRequest.find(id)
      project_merge_request_url(id: merge_request.iid,
                                project_id: merge_request.project,
                                host: Gitlab.config.gitlab['url'])
    end
  end
end
