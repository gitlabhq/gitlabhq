module Issues
  class BaseService < ::IssuableBaseService

    def hook_data(issue, action)
      issue_data = issue.to_hook_data(current_user)
      issue_url = Gitlab::UrlBuilder.new(:issue).build(issue.id)
      issue_data[:object_attributes].merge!(url: issue_url, action: action)
      issue_data
    end

    private

    def filter_params
      super(:issue)
    end

    def execute_hooks(issue, action = 'open')
      issue_data = hook_data(issue, action)
      issue.project.execute_hooks(issue_data, :issue_hooks)
      issue.project.execute_services(issue_data, :issue_hooks)
    end
  end
end
