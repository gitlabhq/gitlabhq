# frozen_string_literal: true

module Gitlab
  module UsageDataConcerns
    module Topology
      include Gitlab::Utils::UsageData

      JOB_TO_SERVICE_NAME = {
        'gitlab-rails' => 'web',
        'gitlab-sidekiq' => 'sidekiq',
        'gitlab-workhorse' => 'workhorse',
        'redis' => 'redis',
        'postgres' => 'postgres',
        'gitaly' => 'gitaly',
        'prometheus' => 'prometheus',
        'node' => 'node-exporter'
      }.freeze

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
          'avg ({__name__ =~ "(ruby_){0,1}process_(resident|unique|proportional)_memory_bytes", job != "gitlab_exporter_process"}) by (instance, job, __name__)'
        )
      end

      def topology_all_service_process_count(client)
        aggregate_many(client, 'count ({__name__ =~ "(ruby_){0,1}process_start_time_seconds", job != "gitlab_exporter_process"}) by (instance, job)')
      end

      def topology_node_services(instance, all_process_counts, all_process_memory)
        # returns all node service data grouped by service name as the key
        instance_service_data =
          topology_instance_service_process_count(instance, all_process_counts)
            .deep_merge(topology_instance_service_memory(instance, all_process_memory))

        # map to list of hashes where service names become values instead, and remove
        # unknown services, since they might not be ours
        instance_service_data.each_with_object([]) do |entry, list|
          service, service_metrics = entry
          gitlab_service = JOB_TO_SERVICE_NAME[service.to_s]
          next unless gitlab_service

          list << { name: gitlab_service }.merge(service_metrics)
        end
      end

      def topology_instance_service_process_count(instance, all_instance_data)
        topology_data_for_instance(instance, all_instance_data).to_h do |metric, count|
          [metric['job'], { process_count: count }]
        end
      end

      def topology_instance_service_memory(instance, all_instance_data)
        topology_data_for_instance(instance, all_instance_data).each_with_object({}) do |entry, hash|
          metric, memory = entry
          job = metric['job']
          key =
            case metric['__name__']
            when match_process_memory_metric_for_type('resident') then :process_memory_rss
            when match_process_memory_metric_for_type('unique') then :process_memory_uss
            when match_process_memory_metric_for_type('proportional') then :process_memory_pss
            end

          hash[job] ||= {}
          hash[job][key] ||= memory
        end
      end

      def match_process_memory_metric_for_type(type)
        /(ruby_){0,1}process_#{type}_memory_bytes/
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
