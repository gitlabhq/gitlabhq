# frozen_string_literal: true

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
        attr_reader :resolver, :interval, :record, :disconnect_timeout

        MAX_SLEEP_ADJUSTMENT = 10

        # nameserver - The nameserver to use for DNS lookups.
        # port - The port of the nameserver.
        # record - The DNS record to look up for retrieving the secondaries.
        # interval - The time to wait between lookups.
        # disconnect_timeout - The time after which an old host should be
        #                      forcefully disconnected.
        def initialize(nameserver:, port:, record:, interval: 60, disconnect_timeout: 120)
          @resolver = Resolv::DNS.new(nameserver_port: [[nameserver, port]])
          @interval = interval
          @record = record
          @disconnect_timeout = disconnect_timeout
        end

        def start
          Thread.new do
            loop do
              interval =
                begin
                  refresh_if_necessary
                rescue => error
                  # Any exceptions that might occur should be reported to
                  # Sentry, instead of silently terminating this thread.
                  Raven.capture_exception(error)

                  Rails.logger.error(
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
        # addresses - An Array of IP addresses to use for the new hosts.
        def replace_hosts(addresses)
          old_hosts = load_balancer.host_list.hosts

          load_balancer.host_list.hosts = addresses.map do |addr|
            Host.new(addr, load_balancer)
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
        # 2. An array containing the IP addresses of the DNS record.
        def addresses_from_dns
          resources =
            resolver.getresources(record, Resolv::DNS::Resource::IN::A)

          # Addresses are sorted so we can directly compare the old and new
          # addresses, without having to use any additional data structures.
          addresses = resources.map { |r| r.address.to_s }.sort

          [new_wait_time_for(resources), addresses]
        end

        def new_wait_time_for(resources)
          wait = resources.first&.ttl || interval

          # The preconfigured interval acts as a minimum amount of time to
          # wait.
          wait < interval ? interval : wait
        end

        def addresses_from_load_balancer
          load_balancer.host_list.host_names.sort
        end

        def load_balancer
          LoadBalancing.proxy.load_balancer
        end
      end
    end
  end
end
