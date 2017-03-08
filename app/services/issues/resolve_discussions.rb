module Issues
  module ResolveDiscussions
    attr_reader :merge_request_for_resolving_discussions_iid, :discussion_to_resolve_id

    def filter_resolve_discussion_params
      @merge_request_for_resolving_discussions_iid ||= params.delete(:merge_request_for_resolving_discussions)
      @discussion_to_resolve_id ||= params.delete(:discussion_to_resolve)
    end

    def merge_request_for_resolving_discussions
      @merge_request_for_resolving_discussions ||= MergeRequestsFinder.new(current_user, project_id: project.id).
                                                     execute.
                                                     find_by(iid: merge_request_for_resolving_discussions_iid)
    end

    def discussions_to_resolve
      return [] unless merge_request_for_resolving_discussions

      @discussions_to_resolve ||= begin
                                    if discussion_to_resolve_id
                                      Array(merge_request_for_resolving_discussions.
                                              find_diff_discussion(discussion_to_resolve_id))
                                    else
                                      merge_request_for_resolving_discussions
                                        .resolvable_discussions
                                    end
                                  end
    end
  end
end
