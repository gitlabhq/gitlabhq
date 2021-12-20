# frozen_string_literal: true

module Namespaces
  class GroupProjectNamespaceSharedPolicy < ::NamespacePolicy
    # Nothing here at the moment, but as we move policies from ProjectPolicy to ProjectNamespacePolicy,
    # anything common with GroupPolicy but not with UserNamespacePolicy can go in here.
    # See https://gitlab.com/groups/gitlab-org/-/epics/6689
  end
end
