# frozen_string_literal: true

class ActiveHookFilter
  def initialize(hook)
    @hook = hook
  end

  def matches?(hooks_scope, data)
    return true unless hooks_scope == :push_hooks

    matches_branch?(data)
  end

  private

  def matches_branch?(data)
    return true if @hook.push_events_branch_filter.blank?

    branch_name = Gitlab::Git.branch_name(data[:ref])

    case @hook.branch_filter_strategy
    when 'all_branches'
      true
    when 'wildcard'
      RefMatcher.new(@hook.push_events_branch_filter).matches?(branch_name)
    when 'regex'
      begin
        Gitlab::UntrustedRegexp.new(@hook.push_events_branch_filter) === branch_name
      rescue RegexpError
        false
      end
    end
  end
end
