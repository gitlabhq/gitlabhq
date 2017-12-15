module Issues
  module ResolveDiscussions
    include Gitlab::Utils::StrongMemoize

    attr_reader :merge_request_to_resolve_discussions_of_iid, :discussion_to_resolve_id

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def filter_resolve_discussion_params
      @merge_request_to_resolve_discussions_of_iid ||= params.delete(:merge_request_to_resolve_discussions_of)
      @discussion_to_resolve_id ||= params.delete(:discussion_to_resolve)
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def merge_request_to_resolve_discussions_of
      strong_memoize(:merge_request_to_resolve_discussions_of) do
        MergeRequestsFinder.new(current_user, project_id: project.id)
          .execute
          .find_by(iid: merge_request_to_resolve_discussions_of_iid)
      end
    end

    def discussions_to_resolve
      return [] unless merge_request_to_resolve_discussions_of

      @discussions_to_resolve ||= # rubocop:disable Gitlab/ModuleWithInstanceVariables
        if discussion_to_resolve_id
          discussion_or_nil = merge_request_to_resolve_discussions_of
                                .find_discussion(discussion_to_resolve_id)
          Array(discussion_or_nil)
        else
          merge_request_to_resolve_discussions_of
            .discussions_to_be_resolved
        end
    end
  end
end
