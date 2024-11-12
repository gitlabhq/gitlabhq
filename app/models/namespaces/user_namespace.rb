# frozen_string_literal: true

module Namespaces
  ####################################################################
  # PLEASE DO NOT OVERRIDE METHODS IN THIS CLASS!
  #
  # This class is a placeholder for STI. But we also want to ensure
  # tests using `:namespace` factory are still testing the same functionality.
  #
  # Many legacy tests use `:namespace` which has a slight semantic
  # mismatch as it always has been a User (personal) namespace.
  #
  # If you need to make a change here, please ping the
  # Tenant Scale group so we can ensure that the
  # changes do not break existing functionality.
  #
  # As Namespaces evolve we may be able to relax this restriction
  # but for now, please check in with us <3
  #
  # For details, see the discussion in
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74152
  ####################################################################

  class UserNamespace < Namespace
    self.allow_legacy_sti_class = true

    def self.sti_name
      'User'
    end

    def owners
      Array.wrap(owner)
    end

    def member?(user, min_access_level = Gitlab::Access::GUEST)
      return false unless user

      max_member_access_for_user(user) >= min_access_level
    end

    # Return the highest access level for a user
    #
    # A special case is handled here when the user is a GitLab admin
    # which implies it has "OWNER" access everywhere, but should not
    # officially appear as a member unless specifically added to it
    #
    # @param user [User]
    # @param only_concrete_membership [Bool] whether require admin concrete membership status
    def max_member_access_for_user(user, only_concrete_membership: false)
      return Gitlab::Access::NO_ACCESS unless user

      if !only_concrete_membership && (user.can_admin_all_resources? || user.can_admin_organization?(organization))
        return Gitlab::Access::OWNER
      end

      owner == user ? Gitlab::Access::OWNER : Gitlab::Access::NO_ACCESS
    end

    def crm_group
      nil
    end
  end
end
