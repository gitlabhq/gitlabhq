# frozen_string_literal: true

require 'net/dns'
require 'resolv'

module Gitlab
  module Database
    module LoadBalancing
      class Resolver
        FAR_FUTURE_TTL = 100.years.from_now

        UnresolvableNameserverError = Class.new(StandardError)

        Response = Class.new do
          attr_reader :address, :ttl

          def initialize(address:, ttl:)
            raise ArgumentError unless ttl.present? && address.present?

            @address = address
            @ttl = ttl
          end
        end

        def initialize(nameserver)
          @nameserver = nameserver
        end

        def resolve
          address = ip_address || ip_address_from_hosts_file ||
            ip_address_from_dns

          unless address
            raise UnresolvableNameserverError,
              "could not resolve #{@nameserver}"
          end

          address
        end

        private

        def ip_address
          # IP addresses are valid forever
          Response.new(address: IPAddr.new(@nameserver), ttl: FAR_FUTURE_TTL)
        rescue IPAddr::InvalidAddressError
        end

        def ip_address_from_hosts_file
          ip = Resolv::Hosts.new.getaddress(@nameserver)
          Response.new(address: IPAddr.new(ip), ttl: FAR_FUTURE_TTL)
        rescue Resolv::ResolvError
        end

        def ip_address_from_dns
          answer = Net::DNS::Resolver.start(@nameserver, Net::DNS::A).answer
          return if answer.empty?

          raw_response = answer.first

          # Defaults to 30 seconds if there is no TTL present
          ttl_in_seconds = raw_response.ttl.presence || 30

          Response.new(address: answer.first.address, ttl: ttl_in_seconds.seconds.from_now)
        rescue Net::DNS::Resolver::NoResponseError
          raise UnresolvableNameserverError, "no response from DNS server(s)"
        end
      end
    end
  end
end
