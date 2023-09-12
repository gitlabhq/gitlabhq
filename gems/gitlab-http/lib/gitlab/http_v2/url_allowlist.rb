# frozen_string_literal: true

require 'gitlab/utils/all'
require_relative 'ip_allowlist_entry'
require_relative 'domain_allowlist_entry'

module Gitlab
  module HTTP_V2
    class UrlAllowlist
      class << self
        def ip_allowed?(ip_string, allowlist, port: nil)
          return false if ip_string.blank?

          ip_allowlist, _ = outbound_local_requests_allowlist_arrays(allowlist)
          ip_obj = ::Gitlab::Utils.string_to_ip_object(ip_string)

          ip_allowlist.any? do |ip_allowlist_entry|
            ip_allowlist_entry.match?(ip_obj, port)
          end
        end

        def domain_allowed?(domain_string, allowlist, port: nil)
          return false if domain_string.blank?

          _, domain_allowlist = outbound_local_requests_allowlist_arrays(allowlist)

          domain_allowlist.any? do |domain_allowlist_entry|
            domain_allowlist_entry.match?(domain_string, port)
          end
        end

        private

        def outbound_local_requests_allowlist_arrays(allowlist)
          return [[], []] if allowlist.blank?

          allowlist.reduce([[], []]) do |(ip_allowlist, domain_allowlist), string|
            address, port = parse_addr_and_port(string)

            ip_obj = ::Gitlab::Utils.string_to_ip_object(address)

            if ip_obj
              ip_allowlist << IpAllowlistEntry.new(ip_obj, port: port)
            else
              domain_allowlist << DomainAllowlistEntry.new(address, port: port)
            end

            [ip_allowlist, domain_allowlist]
          end
        end

        def parse_addr_and_port(str)
          case str
          when /\A\[(?<address> .* )\]:(?<port> \d+ )\z/x      # string like "[::1]:80"
            address = $~[:address]
            port = $~[:port]
          when /\A(?<address> [^:]+ ):(?<port> \d+ )\z/x       # string like "127.0.0.1:80"
            address = $~[:address]
            port = $~[:port]
          else                                                 # string with no port number
            address = str
            port = nil
          end

          [address, port&.to_i]
        end
      end
    end
  end
end
