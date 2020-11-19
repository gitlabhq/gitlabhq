# frozen_string_literal: true

module Gitlab
  module UrlBlockers
    class DomainAllowlistEntry
      attr_reader :domain, :port

      def initialize(domain, port: nil)
        @domain = domain
        @port = port
      end

      def match?(requested_domain, requested_port = nil)
        return false unless domain == requested_domain
        return true if port.nil?

        port == requested_port
      end
    end
  end
end
