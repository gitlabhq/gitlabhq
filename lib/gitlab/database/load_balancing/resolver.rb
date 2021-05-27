# frozen_string_literal: true

require 'net/dns'
require 'resolv'

module Gitlab
  module Database
    module LoadBalancing
      class Resolver
        UnresolvableNameserverError = Class.new(StandardError)

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
          IPAddr.new(@nameserver)
        rescue IPAddr::InvalidAddressError
        end

        def ip_address_from_hosts_file
          ip = Resolv::Hosts.new.getaddress(@nameserver)
          IPAddr.new(ip)
        rescue Resolv::ResolvError
        end

        def ip_address_from_dns
          answer = Net::DNS::Resolver.start(@nameserver, Net::DNS::A).answer
          return if answer.empty?

          answer.first.address
        rescue Net::DNS::Resolver::NoResponseError
          raise UnresolvableNameserverError, "no response from DNS server(s)"
        end
      end
    end
  end
end
