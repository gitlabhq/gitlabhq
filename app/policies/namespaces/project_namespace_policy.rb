# frozen_string_literal: true

module Namespaces
  class ProjectNamespacePolicy < BasePolicy
    # For now users are not granted any permissions on project namespace
    # as it's completely hidden to them. When we start using project
    # namespaces in queries, we will have to extend this policy.
  end
end
