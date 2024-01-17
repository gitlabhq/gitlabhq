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
  end
end
