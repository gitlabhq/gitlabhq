# frozen_string_literal: true

class NamespacePolicy < ::Namespaces::UserNamespacePolicy
  # NamespacePolicy has been traditionally for user namespaces.
  # So these policies have been moved into Namespaces::UserNamespacePolicy.
  # Once the user namespace conversion is complete, we can look at
  # either removing this file or locating common namespace policy items
  # here.
end
