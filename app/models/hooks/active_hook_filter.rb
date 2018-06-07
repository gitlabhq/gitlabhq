class ActiveHookFilter
  def initialize(hook)
    @hook = hook
  end

  def matches?(hooks_scope, data)
    return true if hooks_scope != :push_hooks
    return true if @hook.push_events_branch_filter.blank?

    branch_name = Gitlab::Git.branch_name(data[:ref])
    exact_match?(branch_name) || wildcard_match?(branch_name)
  end

  private

  def exact_match?(branch_name)
    @hook.push_events_branch_filter == branch_name
  end

  def wildcard_match?(branch_name)
    return false unless wildcard?

    wildcard_regex === branch_name
  end

  def wildcard_regex
    @wildcard_regex ||= begin
      name = @hook.push_events_branch_filter.gsub('*', 'STAR_DONT_ESCAPE')
      quoted_name = Regexp.quote(name)
      regex_string = quoted_name.gsub('STAR_DONT_ESCAPE', '.*?')
      /\A#{regex_string}\z/
    end
  end

  def wildcard?
    @hook.push_events_branch_filter && @hook.push_events_branch_filter.include?('*')
  end
end
