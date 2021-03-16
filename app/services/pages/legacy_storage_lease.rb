# frozen_string_literal: true

module Pages
  module LegacyStorageLease
    extend ActiveSupport::Concern

    include ::ExclusiveLeaseGuard

    LEASE_TIMEOUT = 1.hour

    def lease_key
      "pages_legacy_storage:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
