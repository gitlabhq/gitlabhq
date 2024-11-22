# frozen_string_literal: true

module Namespaces
  class GroupProjectNamespaceSharedPolicy < ::NamespacePolicy
    # As we move policies from ProjectPolicy to ProjectNamespacePolicy,
    # anything common with GroupPolicy but not with UserNamespacePolicy can go in here.
    # See https://gitlab.com/groups/gitlab-org/-/epics/6689

    condition(:timelog_categories_enabled, score: 0, scope: :subject) do
      Feature.enabled?(:timelog_categories, @subject)
    end

    rule { ~timelog_categories_enabled }.policy do
      prevent :read_timelog_category
    end

    rule { can?(:reporter_access) }.policy do
      enable :read_timelog_category
      enable :reopen_issue
    end

    rule { can?(:planner_access) }.policy do
      enable :reopen_issue
    end

    rule { can?(:guest_access) }.policy do
      enable :read_work_item
      enable :read_issue
      enable :read_note
      enable :read_namespace
      enable :read_namespace_via_membership
    end
  end
end

Namespaces::GroupProjectNamespaceSharedPolicy.prepend_mod
