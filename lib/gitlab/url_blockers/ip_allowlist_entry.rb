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
        return false unless ip.include?(requested_ip)
        return true if port.nil?

        port == requested_port
      end
    end
  end
end
