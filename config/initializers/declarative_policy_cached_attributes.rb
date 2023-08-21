# frozen_string_literal: true

# This module memoizes some attributes to reduce memory allocations.
#
# See https://gitlab.com/gitlab-org/gitlab/-/issues/420623
# See https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/merge_requests/52
module DeclarativePolicyCachedAttributes
  def ability_map
    @ability_map ||= super
  end

  def conditions
    @conditions ||= super
  end

  def global_actions
    @global_actions ||= super
  end

  def delegations
    @delegations ||= super
  end
end

DeclarativePolicy::Base.singleton_class.prepend(DeclarativePolicyCachedAttributes)
