# frozen_string_literal: true

class NamespacePolicy < BasePolicy
  # NamespacePolicy has been traditionally for user namespaces.
  # So these policies have been moved into Namespaces::UserNamespacePolicy.
  # Once the user namespace conversion is complete, we can look at
  # either removing this file or locating common namespace policy items
  # here.
  # See https://gitlab.com/groups/gitlab-org/-/epics/6689 for details
end
