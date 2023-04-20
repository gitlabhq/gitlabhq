# frozen_string_literal: true

module Gitlab
  module UrlBlockers
    class IpAllowlistEntry
      attr_reader :ip, :port

      # Argument ip should be an IPAddr object
      def initialize(ip, port: nil)
        @ip = ip
        @port = port
      end

      def match?(requested_ip, requested_port = nil)
        requested_ip = IPAddr.new(requested_ip) if requested_ip.is_a?(String)

        return false unless ip_include?(requested_ip)
        return true if port.nil?

        port == requested_port
      end

      private

      # Prior to ipaddr v1.2.3, if the allow list were the IPv4 to IPv6
      # mapped address ::ffff:169.254.168.100 and the requested IP were
      # 169.254.168.100 or ::ffff:169.254.168.100, the IP would be
      # considered in the allow list. However, with
      # https://github.com/ruby/ipaddr/pull/31, IPAddr#include? will
      # only match if the IP versions are the same. This method
      # preserves backwards compatibility if the versions differ by
      # checking inclusion by coercing an IPv4 address to its IPv6
      # mapped address.
      def ip_include?(requested_ip)
        return true if ip.include?(requested_ip)
        return ip.include?(requested_ip.ipv4_mapped) if requested_ip.ipv4? && ip.ipv6?
        return ip.ipv4_mapped.include?(requested_ip) if requested_ip.ipv6? && ip.ipv4?

        false
      end
    end
  end
end
