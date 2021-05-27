# frozen_string_literal: true

require 'net/dns'
require 'resolv'

module Gitlab
  module Database
    module LoadBalancing
      # Service discovery of secondary database hosts.
      #
      # Service discovery works by periodically looking up a DNS record. If the
      # DNS record returns a new list of hosts, this class will update the load
      # balancer with said hosts. Requests may continue to use the old hosts
      # until they complete.
      class ServiceDiscovery
        attr_reader :interval, :record, :record_type, :disconnect_timeout

        MAX_SLEEP_ADJUSTMENT = 10

        RECORD_TYPES = {
          'A' => Net::DNS::A,
          'SRV' => Net::DNS::SRV
        }.freeze

        Address = Struct.new(:hostname, :port) do
          def to_s
            port ? "#{hostname}:#{port}" : hostname
          end

          def <=>(other)
            self.to_s <=> other.to_s
          end
        end

        # nameserver - The nameserver to use for DNS lookups.
        # port - The port of the nameserver.
        # record - The DNS record to look up for retrieving the secondaries.
        # record_type - The type of DNS record to look up
        # interval - The time to wait between lookups.
        # disconnect_timeout - The time after which an old host should be
        #                      forcefully disconnected.
        # use_tcp - Use TCP instaed of UDP to look up resources
        def initialize(nameserver:, port:, record:, record_type: 'A', interval: 60, disconnect_timeout: 120, use_tcp: false)
          @nameserver = nameserver
          @port = port
          @record = record
          @record_type = record_type_for(record_type)
          @interval = interval
          @disconnect_timeout = disconnect_timeout
          @use_tcp = use_tcp
        end

        def start
          Thread.new do
            loop do
              interval =
                begin
                  refresh_if_necessary
                rescue StandardError => error
                  # Any exceptions that might occur should be reported to
                  # Sentry, instead of silently terminating this thread.
                  Gitlab::ErrorTracking.track_exception(error)

                  Gitlab::AppLogger.error(
                    "Service discovery encountered an error: #{error.message}"
                  )

                  self.interval
                end

              # We slightly randomize the sleep() interval. This should reduce
              # the likelihood of _all_ processes refreshing at the same time,
              # possibly putting unnecessary pressure on the DNS server.
              sleep(interval + rand(MAX_SLEEP_ADJUSTMENT))
            end
          end
        end

        # Refreshes the hosts, but only if the DNS record returned a new list of
        # addresses.
        #
        # The return value is the amount of time (in seconds) to wait before
        # checking the DNS record for any changes.
        def refresh_if_necessary
          interval, from_dns = addresses_from_dns

          current = addresses_from_load_balancer

          replace_hosts(from_dns) if from_dns != current

          interval
        end

        # Replaces all the hosts in the load balancer with the new ones,
        # disconnecting the old connections.
        #
        # addresses - An Array of Address structs to use for the new hosts.
        def replace_hosts(addresses)
          old_hosts = load_balancer.host_list.hosts

          load_balancer.host_list.hosts = addresses.map do |addr|
            Host.new(addr.hostname, load_balancer, port: addr.port)
          end

          # We must explicitly disconnect the old connections, otherwise we may
          # leak database connections over time. For example, if a request
          # started just before we added the new hosts it will use an old
          # host/connection. While this connection will be checked in and out,
          # it won't be explicitly disconnected.
          old_hosts.each do |host|
            host.disconnect!(disconnect_timeout)
          end
        end

        # Returns an Array containing:
        #
        # 1. The time to wait for the next check.
        # 2. An array containing the hostnames of the DNS record.
        def addresses_from_dns
          response = resolver.search(record, record_type)
          resources = response.answer

          addresses =
            case record_type
            when Net::DNS::A
              addresses_from_a_record(resources)
            when Net::DNS::SRV
              addresses_from_srv_record(response)
            end

          # Addresses are sorted so we can directly compare the old and new
          # addresses, without having to use any additional data structures.
          [new_wait_time_for(resources), addresses.sort]
        end

        def new_wait_time_for(resources)
          wait = resources.first&.ttl || interval

          # The preconfigured interval acts as a minimum amount of time to
          # wait.
          wait < interval ? interval : wait
        end

        def addresses_from_load_balancer
          load_balancer.host_list.host_names_and_ports.map do |hostname, port|
            Address.new(hostname, port)
          end.sort
        end

        def load_balancer
          LoadBalancing.proxy.load_balancer
        end

        def resolver
          @resolver ||= Net::DNS::Resolver.new(
            nameservers: Resolver.new(@nameserver).resolve,
            port: @port,
            use_tcp: @use_tcp
          )
        end

        private

        def record_type_for(type)
          RECORD_TYPES.fetch(type) do
            raise(ArgumentError, "Unsupported record type: #{type}")
          end
        end

        def addresses_from_srv_record(response)
          srv_resolver = SrvResolver.new(resolver, response.additional)

          response.answer.map do |r|
            address = srv_resolver.address_for(r.host.to_s)
            next unless address

            Address.new(address.to_s, r.port)
          end.compact
        end

        def addresses_from_a_record(resources)
          resources.map { |r| Address.new(r.address.to_s) }
        end
      end
    end
  end
end
