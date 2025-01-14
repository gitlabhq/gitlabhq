# frozen_string_literal: true

module Issues
  module ResolveDiscussions
    include Gitlab::Utils::StrongMemoize

    attr_reader :merge_request_to_resolve_discussions_of_iid,
      :discussion_to_resolve_id,
      :merge_request_to_resolve_discussions_object

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def filter_resolve_discussion_params
      @merge_request_to_resolve_discussions_object ||= params.delete(:merge_request_to_resolve_discussions_object)
      @merge_request_to_resolve_discussions_of_iid ||= params.delete(:merge_request_to_resolve_discussions_of)
      @discussion_to_resolve_id ||= params.delete(:discussion_to_resolve)
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_request_to_resolve_discussions_of
      strong_memoize(:merge_request_to_resolve_discussions_of) do
        # sometimes this will be a Group, when work item is created at group level.
        # Not sure if we will need to handle resolving an MR with an issue at group level?
        next unless container.is_a?(Project)
        next merge_request_to_resolve_discussions_object if merge_request_to_resolve_discussions_object.present?

        MergeRequestsFinder.new(current_user, project_id: container.id)
          .find_by(iid: merge_request_to_resolve_discussions_of_iid)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

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
        end.reject(&:confidential?)
    end
  end
end
