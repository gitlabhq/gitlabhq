module Issues
  class BaseService < ::IssuableBaseService
    attr_reader :merge_request_for_resolving_discussions_iid, :discussion_to_resolve_id
    def initialize(*args)
      super

      @merge_request_for_resolving_discussions_iid ||= params.delete(:merge_request_for_resolving_discussions)
      @discussion_to_resolve_id ||= params.delete(:discussion_to_resolve)
    end

    def hook_data(issue, action)
      issue_data = issue.to_hook_data(current_user)
      issue_url = Gitlab::UrlBuilder.build(issue)
      issue_data[:object_attributes].merge!(url: issue_url, action: action)
      issue_data
    end

    def merge_request_for_resolving_discussions
      @merge_request_for_resolving_discussions ||= MergeRequestsFinder.new(current_user, project_id: project.id).
                                                     execute.
                                                     find_by(iid: merge_request_for_resolving_discussions_iid)
    end

    def discussions_to_resolve
      return [] unless merge_request_for_resolving_discussions

      @discussions_to_resolve ||= NotesFinder.new(project, current_user, {
                                                    discussion_id: discussion_to_resolve_id,
                                                    target_type: MergeRequest.name.underscore,
                                                    target_id: merge_request_for_resolving_discussions.id
                                                  }).
                                    execute.
                                    discussions.
                                    select(&:to_be_resolved?)
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
