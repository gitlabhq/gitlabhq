module Issues
  class BaseService < ::IssuableBaseService
    attr_reader :merge_request_for_resolving_discussions

    def initialize(*args)
      super

      @merge_request_for_resolving_discussions ||= params.delete(:merge_request_for_resolving_discussions)
    end

    def hook_data(issue, action)
      issue_data = issue.to_hook_data(current_user)
      issue_url = Gitlab::UrlBuilder.build(issue)
      issue_data[:object_attributes].merge!(url: issue_url, action: action)
      issue_data
    end

    private

    def execute_hooks(issue, action = 'open')
      issue_data  = hook_data(issue, action)
      hooks_scope = issue.confidential? ? :confidential_issue_hooks : :issue_hooks
      issue.project.execute_hooks(issue_data, hooks_scope)
      issue.project.execute_services(issue_data, hooks_scope)
    end
  end
end
