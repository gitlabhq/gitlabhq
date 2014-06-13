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
      end
    end

    private

    def issue_url(id)
      issue = Issue.find(id)
      project_issue_url(id: issue.iid,
                        project_id: issue.project,
                        host: Settings.gitlab['url'])
    end
  end
end
