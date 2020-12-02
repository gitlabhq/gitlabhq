# frozen_string_literal: true

module Pages
  module LegacyStorageLease
    extend ActiveSupport::Concern

    include ::ExclusiveLeaseGuard

    LEASE_TIMEOUT = 1.hour

    # override method from exclusive lease guard to guard it by feature flag
    # TODO: just remove this method after testing this in production
    # https://gitlab.com/gitlab-org/gitlab/-/issues/282464
    def try_obtain_lease
      return yield unless Feature.enabled?(:pages_use_legacy_storage_lease, project)

      super
    end

    def lease_key
      "pages_legacy_storage:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
