# frozen_string_literal: true

module Gitlab
  module UsageDataConcerns
    module Topology
      include Gitlab::Utils::UsageData

      def topology_usage_data
        topology_data, duration = measure_duration do
          alt_usage_data(fallback: {}) do
            {
              nodes: topology_node_data
            }.compact
          end
        end
        { topology: topology_data.merge(duration_s: duration) }
      end

      private

      def topology_node_data
        with_prometheus_client do |client|
          # node-level data
          by_instance_mem = topology_node_memory(client)
          by_instance_cpus = topology_node_cpus(client)
          # service-level data
          by_instance_by_job_by_metric_memory = topology_all_service_memory(client)
          by_instance_by_job_process_count = topology_all_service_process_count(client)

          instances = Set.new(by_instance_mem.keys + by_instance_cpus.keys)
          instances.map do |instance|
            {
              node_memory_total_bytes: by_instance_mem[instance],
              node_cpus: by_instance_cpus[instance],
              node_services:
                topology_node_services(instance, by_instance_by_job_process_count, by_instance_by_job_by_metric_memory)
            }.compact
          end
        end
      end

      def topology_node_memory(client)
        aggregate_single(client, 'avg (node_memory_MemTotal_bytes) by (instance)')
      end

      def topology_node_cpus(client)
        aggregate_single(client, 'count (node_cpu_seconds_total{mode="idle"}) by (instance)')
      end

      def topology_all_service_memory(client)
        aggregate_many(
          client,
          'avg ({__name__=~"ruby_process_(resident|unique|proportional)_memory_bytes"}) by (instance, job, __name__)'
        )
      end

      def topology_all_service_process_count(client)
        aggregate_many(client, 'count (ruby_process_start_time_seconds) by (instance, job)')
      end

      def topology_node_services(instance, all_process_counts, all_process_memory)
        # returns all node service data grouped by service name as the key
        instance_service_data =
          topology_instance_service_process_count(instance, all_process_counts)
            .deep_merge(topology_instance_service_memory(instance, all_process_memory))

        # map to list of hashes where service name becomes a value instead
        instance_service_data.map do |service, data|
          { name: service.to_s }.merge(data)
        end
      end

      def topology_instance_service_process_count(instance, all_instance_data)
        topology_data_for_instance(instance, all_instance_data).to_h do |metric, count|
          job = metric['job'].underscore.to_sym
          [job, { process_count: count }]
        end
      end

      def topology_instance_service_memory(instance, all_instance_data)
        topology_data_for_instance(instance, all_instance_data).each_with_object({}) do |entry, hash|
          metric, memory = entry
          job = metric['job'].underscore.to_sym
          key =
            case metric['__name__']
            when 'ruby_process_resident_memory_bytes' then :process_memory_rss
            when 'ruby_process_unique_memory_bytes' then :process_memory_uss
            when 'ruby_process_proportional_memory_bytes' then :process_memory_pss
            end

          hash[job] ||= {}
          hash[job][key] ||= memory
        end
      end

      def topology_data_for_instance(instance, all_instance_data)
        all_instance_data.filter { |metric, _value| metric['instance'] == instance }
      end

      def drop_port(instance)
        instance.gsub(/:.+$/, '')
      end

      # Will retain a single `instance` key that values are mapped to
      def aggregate_single(client, query)
        client.aggregate(query) { |metric| drop_port(metric['instance']) }
      end

      # Will retain a composite key that values are mapped to
      def aggregate_many(client, query)
        client.aggregate(query) do |metric|
          metric['instance'] = drop_port(metric['instance'])
          metric
        end
      end
    end
  end
end
