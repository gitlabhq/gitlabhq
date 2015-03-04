module Gitlab
  class UrlBuilder
    include Rails.application.routes.url_helpers
    include GitlabRoutingHelper

    def initialize(type)
      @type = type
    end

    def build(id)
      case @type
      when :issue
        build_issue_url(id)
      when :merge_request
        build_merge_request_url(id)
      end
    end

    private

    def build_issue_url(id)
      issue = Issue.find(id)
      issue_url(issue, host: Gitlab.config.gitlab['url'])
    end

    def build_merge_request_url(id)
      merge_request = MergeRequest.find(id)
      merge_request_url(merge_request, host: Gitlab.config.gitlab['url'])
    end
  end
end
