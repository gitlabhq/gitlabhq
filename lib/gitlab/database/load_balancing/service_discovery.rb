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
        EmptyDnsResponse = Class.new(StandardError)

        attr_accessor :refresh_thread, :refresh_thread_last_run, :refresh_thread_interruption_logged

        attr_reader :interval, :record, :record_type, :disconnect_timeout,
          :load_balancer

        MAX_SLEEP_ADJUSTMENT = 10
        MAX_DISCOVERY_RETRIES = 3
        DISCOVERY_THREAD_REFRESH_DELTA = 5

        RETRY_DELAY_RANGE = (0.1..0.2)

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
        # load_balancer - The load balancer instance to use
        # rubocop:disable Metrics/ParameterLists
        def initialize(
          load_balancer,
          nameserver:,
          port:,
          record:,
          record_type: 'A',
          interval: 60,
          disconnect_timeout: 120,
          use_tcp: false,
          max_replica_pools: nil
        )
          @nameserver = nameserver
          @port = port
          @record = record
          @record_type = record_type_for(record_type)
          @interval = interval
          @disconnect_timeout = disconnect_timeout
          @use_tcp = use_tcp
          @load_balancer = load_balancer
          @max_replica_pools = max_replica_pools
          @nameserver_ttl = 1.second.ago # Begin with an expired ttl to trigger a nameserver dns lookup
        end
        # rubocop:enable Metrics/ParameterLists

        def start
          self.refresh_thread = Thread.new do
            loop do
              self.refresh_thread_last_run = Time.current

              next_sleep_duration = perform_service_discovery

              # We slightly randomize the sleep() interval. This should reduce
              # the likelihood of _all_ processes refreshing at the same time,
              # possibly putting unnecessary pressure on the DNS server.
              sleep(next_sleep_duration + rand(MAX_SLEEP_ADJUSTMENT))
            end
          end
        end

        def perform_service_discovery
          MAX_DISCOVERY_RETRIES.times do
            return refresh_if_necessary
          rescue StandardError => error
            # Any exceptions that might occur should be reported to
            # Sentry, instead of silently terminating this thread.
            Gitlab::ErrorTracking.track_exception(error)

            Gitlab::Database::LoadBalancing::Logger.error(
              event: :service_discovery_failure,
              message: "Service discovery encountered an error: #{error.message}",
              host_list_length: load_balancer.host_list.length,
              backtrace: error.backtrace
            )

            # Slightly randomize the retry delay so that, in the case of a total
            # dns outage, all starting services do not pressure the dns server at the same time.
            sleep(rand(RETRY_DELAY_RANGE))
          end

          interval
        end

        # Refreshes the hosts, but only if the DNS record returned a new list of
        # addresses.
        #
        # The return value is the amount of time (in seconds) to wait before
        # checking the DNS record for any changes.
        def refresh_if_necessary
          wait_time, from_dns = addresses_from_dns

          current = addresses_from_load_balancer

          if from_dns != current
            ::Gitlab::Database::LoadBalancing::Logger.info(
              event: :host_list_update,
              message: "Updating the host list for service discovery",
              host_list_length: from_dns.length,
              old_host_list_length: current.length
            )
            replace_hosts(from_dns)
          end

          wait_time
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
          disconnect_old_hosts(old_hosts)
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

          addresses = sampler.sample(addresses)

          raise EmptyDnsResponse if addresses.empty?

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

        def resolver
          return @resolver if defined?(@resolver) && @nameserver_ttl.future?

          response = Resolver.new(@nameserver).resolve

          @nameserver_ttl = response.ttl

          @resolver = Net::DNS::Resolver.new(
            nameservers: response.address,
            port: @port,
            use_tcp: @use_tcp
          )
        end

        def log_refresh_thread_interruption
          return if refresh_thread_last_run.blank? || refresh_thread_interruption_logged ||
            (refresh_thread_last_run + DISCOVERY_THREAD_REFRESH_DELTA.minutes).future?

          Gitlab::Database::LoadBalancing::Logger.error(
            event: :service_discovery_refresh_thread_interrupt,
            refresh_thread_last_run: refresh_thread_last_run,
            thread_status: refresh_thread&.status&.to_s,
            thread_backtrace: refresh_thread&.backtrace&.join('\n')
          )

          self.refresh_thread_interruption_logged = true
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

        def sampler
          @sampler ||= ::Gitlab::Database::LoadBalancing::ServiceDiscovery::Sampler
            .new(max_replica_pools: @max_replica_pools)
        end

        def disconnect_old_hosts(hosts)
          return unless hosts.present?

          gentle_disconnect_start = ::Gitlab::Metrics::System.monotonic_time
          gentle_disconnect_deadline = gentle_disconnect_start + disconnect_timeout

          hosts_to_disconnect = hosts

          gentle_disconnected_hosts = []
          gentle_disconnect_duration = Benchmark.realtime do
            while ::Gitlab::Metrics::System.monotonic_time < gentle_disconnect_deadline
              newly_disconnected, still_to_disconnect = hosts_to_disconnect.partition(&:try_disconnect)
              gentle_disconnected_hosts.concat(newly_disconnected)
              hosts_to_disconnect = still_to_disconnect
              break if hosts_to_disconnect.empty?

              sleep(2)
            end
          end

          force_disconnect_duration = Benchmark.realtime do
            # This may wait up to 2 * pool.checkout_timeout per host (default 10 seconds per host)
            hosts_to_disconnect.each(&:force_disconnect!)
          end

          force_disconnected_hosts = hosts_to_disconnect

          formatted_gentle_hosts = gentle_disconnected_hosts.map { |h| "#{h.host}:#{h.port}" }
          formatted_forced_hosts = force_disconnected_hosts.map { |h| "#{h.host}:#{h.port}" }
          total_disconnect_duration = gentle_disconnect_duration + force_disconnect_duration

          formatted_all_hosts = formatted_gentle_hosts + formatted_forced_hosts

          ::Gitlab::Database::LoadBalancing::Logger.info(
            event: :host_list_disconnection,
            message: "Disconnected #{formatted_all_hosts} old load balancing hosts after #{total_disconnect_duration}s",
            gentle_disconnected_hosts: formatted_gentle_hosts,
            force_disconnected_hosts: formatted_forced_hosts,
            gentle_disconnect_duration_s: gentle_disconnect_duration,
            force_disconnect_duration_s: force_disconnect_duration,
            total_disconnect_duration_s: total_disconnect_duration
          )
        end
      end
    end
  end
end
