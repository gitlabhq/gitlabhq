# frozen_string_literal: true

module Namespaces
  class ProjectNamespacePolicy < Namespaces::GroupProjectNamespaceSharedPolicy
    # TODO: once https://gitlab.com/gitlab-org/gitlab/-/issues/364277 is solved, this
    # should not be necessary anymore, and should be replaced with `delegate(:project)`.
    delegate(:reload_project)
  end
end
