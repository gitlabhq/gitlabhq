class ActiveHookFilter
  def initialize(hook)
    @hook = hook
    @push_events_filter_matcher = RefMatcher.new(@hook.push_events_branch_filter)
  end

  def matches?(hooks_scope, data)
    return true if hooks_scope != :push_hooks
    return true if @hook.push_events_branch_filter.blank?

    branch_name = Gitlab::Git.branch_name(data[:ref])
    @push_events_filter_matcher.matches?(branch_name)
  end
end
