# frozen_string_literal: true

module Gitlab
  module UrlBlockers
    class UrlAllowlist
      class << self
        def ip_allowed?(ip_string, port: nil)
          return false if ip_string.blank?

          ip_allowlist, _ = outbound_local_requests_allowlist_arrays
          ip_obj = Gitlab::Utils.string_to_ip_object(ip_string)

          ip_allowlist.any? do |ip_allowlist_entry|
            ip_allowlist_entry.match?(ip_obj, port)
          end
        end

        def domain_allowed?(domain_string, port: nil)
          return false if domain_string.blank?

          _, domain_allowlist = outbound_local_requests_allowlist_arrays

          domain_allowlist.any? do |domain_allowlist_entry|
            domain_allowlist_entry.match?(domain_string, port)
          end
        end

        private

        # We cannot use Gitlab::CurrentSettings as ApplicationSetting itself
        # calls this class. This ends up in a cycle where
        # Gitlab::CurrentSettings creates an ApplicationSetting which then
        # calls this method.
        #
        # See https://gitlab.com/gitlab-org/gitlab/issues/9833
        def outbound_local_requests_allowlist_arrays
          return [[], []] unless ApplicationSetting.current

          ApplicationSetting.current.outbound_local_requests_allowlist_arrays
        end
      end
    end
  end
end
