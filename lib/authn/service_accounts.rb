# frozen_string_literal: true

module Authn
  class ServiceAccounts
    # Default limits for free/unlicensed tiers. Enforced in EE for both SM
    # (instance-wide) and SaaS (namespace-scoped) service account creation checks.
    # Related discussion - https://gitlab.com/gitlab-org/gitlab/-/issues/540776#note_3099330149
    LIMIT_FOR_FREE = 100
    LIMIT_FOR_TRIAL = 100

    class << self
      # CE self-managed has no license, so it is always on the free tier.
      # LIMIT_FOR_FREE applies to all CE instances.
      # Overridden in EE to allow unlimited creation for paid SM licenses.
      def creation_allowed_for_sm?(_root_namespace = nil)
        LIMIT_FOR_FREE > ::User.service_accounts.count
      end

      # Returns true in CE - SaaS subscription checks do not apply.
      # Overridden in EE to enforce tier-based limits for SaaS namespaces.
      def creation_allowed_for_saas?(_root_namespace = nil, _provisioned_count = 0)
        true
      end

      # Returns true in CE - CE has no license, always considered free tier.
      # Overridden in EE to check against the actual SM license.
      def free_tier?(_root_namespace = nil)
        true
      end

      # Returns false in CE - no SaaS subscription concept without GitLab.com.
      # Overridden in EE to detect free SaaS namespaces.
      def free_tier_namespace?(_namespace)
        false
      end
    end
  end
end

Authn::ServiceAccounts.prepend_mod
