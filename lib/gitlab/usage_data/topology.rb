# frozen_string_literal: true

module Gitlab
  class UsageData
    class Topology
      include Gitlab::Utils::UsageData

      JOB_TO_SERVICE_NAME = {
        'gitlab-rails' => 'web',
        'gitlab-sidekiq' => 'sidekiq',
        'gitlab-workhorse' => 'workhorse',
        'redis' => 'redis',
        'postgres' => 'postgres',
        'gitaly' => 'gitaly',
        'prometheus' => 'prometheus',
        'node' => 'node-exporter',
        'registry' => 'registry'
      }.freeze

      # If these errors occur, all subsequent queries are likely to fail for the same error
      TIMEOUT_ERRORS = [Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout].freeze

      CollectionFailure = Struct.new(:query, :error) do
        def to_h
          { query => error }
        end
      end

      def topology_usage_data
        @failures = []
        @instances = Set[]
        topology_data, duration = measure_duration { topology_fetch_all_data }
        {
          topology: topology_data
                      .merge(duration_s: duration)
                      .merge(failures: @failures.map(&:to_h))
        }
      end

      private

      def topology_fetch_all_data
        with_prometheus_client(fallback: {}, verify: false) do |client|
          {
            application_requests_per_hour: topology_app_requests_per_hour(client),
            query_apdex_weekly_average: topology_query_apdex_weekly_average(client),
            nodes: topology_node_data(client)
          }.compact
        end
      rescue StandardError => e
        @failures << CollectionFailure.new('other', e.class.to_s)

        {}
      end

      def topology_app_requests_per_hour(client)
        result = query_safely('gitlab_usage_ping:ops:rate5m', 'app_requests', fallback: nil) do |query|
          client.query(aggregate_one_week(query)).first
        end

        return unless result

        # the metric is recorded as a per-second rate
        (result['value'].last.to_f * 1.hour).to_i
      end

      def topology_query_apdex_weekly_average(client)
        result = query_safely('gitlab_usage_ping:sql_duration_apdex:ratio_rate5m', 'query_apdex', fallback: nil) do |query|
          client.query(aggregate_one_week(query)).first
        end

        return unless result

        result['value'].last.to_f
      end

      def topology_node_data(client)
        # node-level data
        by_instance_mem = topology_node_memory(client)
        by_instance_mem_utilization = topology_node_memory_utilization(client)
        by_instance_cpus = topology_node_cpus(client)
        by_instance_cpu_utilization = topology_node_cpu_utilization(client)
        by_instance_uname_info = topology_node_uname_info(client)
        # service-level data
        by_instance_by_job_by_type_memory = topology_all_service_memory(client)
        by_instance_by_job_process_count = topology_all_service_process_count(client)
        by_instance_by_job_server_types = topology_all_service_server_types(client)

        @instances.map do |instance|
          {
            node_memory_total_bytes: by_instance_mem[instance],
            node_memory_utilization: by_instance_mem_utilization[instance],
            node_cpus: by_instance_cpus[instance],
            node_cpu_utilization: by_instance_cpu_utilization[instance],
            node_uname_info: by_instance_uname_info[instance],
            node_services:
              topology_node_services(
                instance, by_instance_by_job_process_count, by_instance_by_job_by_type_memory, by_instance_by_job_server_types
              )
          }.compact
        end
      end

      def topology_node_memory(client)
        query_safely('gitlab_usage_ping:node_memory_total_bytes:max', 'node_memory', fallback: {}) do |query|
          aggregate_by_instance(client, aggregate_one_week(query, aggregation: :max))
        end
      end

      def topology_node_memory_utilization(client)
        query_safely('gitlab_usage_ping:node_memory_utilization:avg', 'node_memory_utilization', fallback: {}) do |query|
          aggregate_by_instance(client, aggregate_one_week(query), transform_value: :to_f)
        end
      end

      def topology_node_cpus(client)
        query_safely('gitlab_usage_ping:node_cpus:count', 'node_cpus', fallback: {}) do |query|
          aggregate_by_instance(client, aggregate_one_week(query, aggregation: :max))
        end
      end

      def topology_node_cpu_utilization(client)
        query_safely('gitlab_usage_ping:node_cpu_utilization:avg', 'node_cpu_utilization', fallback: {}) do |query|
          aggregate_by_instance(client, aggregate_one_week(query), transform_value: :to_f)
        end
      end

      def topology_node_uname_info(client)
        node_uname_info = query_safely('node_uname_info', 'node_uname_info', fallback: []) do |query|
          client.query(query)
        end

        map_instance_labels(node_uname_info, %w(machine sysname release))
      end

      def topology_all_service_memory(client)
        {
          rss: topology_service_memory_rss(client),
          uss: topology_service_memory_uss(client),
          pss: topology_service_memory_pss(client)
        }
      end

      def topology_service_memory_rss(client)
        query_safely(
          'gitlab_usage_ping:node_service_process_resident_memory_bytes:avg', 'service_rss', fallback: {}
        ) { |query| aggregate_by_labels(client, aggregate_one_week(query)) }
      end

      def topology_service_memory_uss(client)
        query_safely(
          'gitlab_usage_ping:node_service_process_unique_memory_bytes:avg', 'service_uss', fallback: {}
        ) { |query| aggregate_by_labels(client, aggregate_one_week(query)) }
      end

      def topology_service_memory_pss(client)
        query_safely(
          'gitlab_usage_ping:node_service_process_proportional_memory_bytes:avg', 'service_pss', fallback: {}
        ) { |query| aggregate_by_labels(client, aggregate_one_week(query)) }
      end

      def topology_all_service_process_count(client)
        query_safely(
          'gitlab_usage_ping:node_service_process:count', 'service_process_count', fallback: {}
        ) { |query| aggregate_by_labels(client, aggregate_one_week(query)) }
      end

      def topology_all_service_server_types(client)
        query_safely(
          'gitlab_usage_ping:node_service_app_server_workers:sum', 'service_workers', fallback: {}
        ) { |query| aggregate_by_labels(client, query) }
      end

      def query_safely(query, query_name, fallback:)
        if timeout_error_exists?
          @failures << CollectionFailure.new(query_name, 'timeout_cancellation')
          return fallback
        end

        result = yield query

        return result if result.present?

        @failures << CollectionFailure.new(query_name, 'empty_result')
        fallback
      rescue StandardError => e
        @failures << CollectionFailure.new(query_name, e.class.to_s)
        fallback
      end

      def timeout_error_exists?
        timeout_error_names = TIMEOUT_ERRORS.map(&:to_s).to_set

        @failures.any? do |failure|
          timeout_error_names.include?(failure.error)
        end
      end

      def topology_node_services(instance, all_process_counts, all_process_memory, all_server_types)
        # returns all node service data grouped by service name as the key
        instance_service_data =
          topology_instance_service_process_count(instance, all_process_counts)
            .deep_merge(topology_instance_service_memory(instance, all_process_memory))
            .deep_merge(topology_instance_service_server_types(instance, all_server_types))

        # map to list of hashes where service names become values instead, and skip
        # unknown services, since they might not be ours
        instance_service_data.each_with_object([]) do |entry, list|
          service, service_metrics = entry
          service_name = service.to_s.strip

          if gitlab_service = JOB_TO_SERVICE_NAME[service_name]
            list << { name: gitlab_service }.merge(service_metrics)
          else
            @failures << CollectionFailure.new('service_unknown', service_name)
          end
        end
      end

      def topology_instance_service_process_count(instance, all_instance_data)
        topology_data_for_instance(instance, all_instance_data).to_h do |metric, count|
          [metric['job'], { process_count: count }]
        end
      end

      # Given a hash mapping memory set types to Prometheus response data, returns a hash
      # mapping instance/node names to services and their respective memory use in bytes
      def topology_instance_service_memory(instance, instance_data_by_type)
        result = {}
        instance_data_by_type.each do |memory_type, instance_data|
          topology_data_for_instance(instance, instance_data).each do |metric, memory_bytes|
            job = metric['job']
            key = "process_memory_#{memory_type}".to_sym

            result[job] ||= {}
            result[job][key] ||= memory_bytes
          end
        end

        result
      end

      def topology_instance_service_server_types(instance, all_instance_data)
        topology_data_for_instance(instance, all_instance_data).to_h do |metric, _value|
          [metric['job'], { server: metric['server'] }]
        end
      end

      def topology_data_for_instance(instance, all_instance_data)
        all_instance_data.filter { |metric, _value| metric['instance'] == instance }
      end

      def normalize_instance_label(instance)
        normalize_localhost_address(drop_port_number(instance))
      end

      def normalize_localhost_address(instance)
        ip_addr = IPAddr.new(instance)
        is_local_ip = ip_addr.loopback? || ip_addr.to_i == 0

        is_local_ip ? 'localhost' : instance
      rescue IPAddr::InvalidAddressError
        # This most likely means it was a host name, not an IP address
        instance
      end

      def drop_port_number(instance)
        instance.gsub(/:\d+$/, '')
      end

      def normalize_and_track_instance(instance)
        normalize_instance_label(instance).tap do |normalized_instance|
          @instances << normalized_instance
        end
      end

      def aggregate_one_week(query, aggregation: :avg)
        "#{aggregation}_over_time (#{query}[1w])"
      end

      def aggregate_by_instance(client, query, transform_value: :to_i)
        client.aggregate(query, transform_value: transform_value) { |metric| normalize_and_track_instance(metric['instance']) }
      end

      # Will retain a composite key that values are mapped to
      def aggregate_by_labels(client, query, transform_value: :to_i)
        client.aggregate(query, transform_value: transform_value) do |metric|
          metric['instance'] = normalize_and_track_instance(metric['instance'])
          metric
        end
      end

      # Given query result vector, map instance to a hash of target labels key/value.
      # @return [Hash] mapping instance to a hash of target labels key/value, or the empty hash if input empty vector
      def map_instance_labels(query_result_vector, target_labels)
        query_result_vector.to_h do |result|
          key = normalize_and_track_instance(result['metric']['instance'])
          value = result['metric'].slice(*target_labels).symbolize_keys
          [key, value]
        end
      end
    end
  end
end
