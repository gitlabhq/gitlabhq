module Issues
  class BaseService < ::IssuableBaseService

    private

    def execute_hooks(issue, action = 'open')
      issue_data = issue.to_hook_data(current_user)
      issue_url = Gitlab::UrlBuilder.new(:issue).build(issue.id)
      issue_data[:object_attributes].merge!(url: issue_url, action: action)
      issue.project.execute_hooks(issue_data, :issue_hooks)
    end
  end
end
