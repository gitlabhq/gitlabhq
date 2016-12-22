module Issues
  class BaseService < ::IssuableBaseService
    attr_reader :merge_request_for_resolving_discussions, :discussion_to_resolve

    def initialize(*args)
      super

      @merge_request_for_resolving_discussions ||= params.delete(:merge_request_for_resolving_discussions)
      @discussion_to_resolve ||= params.delete(:discussion_to_resolve)
    end

    def hook_data(issue, action)
      issue_data = issue.to_hook_data(current_user)
      issue_url = Gitlab::UrlBuilder.build(issue)
      issue_data[:object_attributes].merge!(url: issue_url, action: action)
      issue_data
    end

    def merge_request_for_resolving_discussions
      @merge_request_for_resolving_discussions ||= discussion_to_resolve.try(:noteable)
    end

    def for_all_discussions_in_a_merge_request?
      discussion_to_resolve.nil? && merge_request_for_resolving_discussions
    end

    def for_single_discussion?
      discussion_to_resolve && discussion_to_resolve.noteable == merge_request_for_resolving_discussions
    end

    def discussions_to_resolve
      @discussions_to_resolve ||= if for_all_discussions_in_a_merge_request?
                                    merge_request_for_resolving_discussions.resolvable_discussions
                                  elsif for_single_discussion?
                                    Array(discussion_to_resolve)
                                  else
                                    []
                                  end
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
