# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class DatabaseSampler < BaseSampler
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 5

        METRIC_PREFIX = 'gitlab_database_connection_pool_'

        METRIC_DESCRIPTIONS = {
          size: 'Total connection pool capacity',
          connections: 'Current connections in the pool',
          busy: 'Connections in use where the owner is still alive',
          dead: 'Connections in use where the owner is not alive',
          idle: 'Connections not in use',
          waiting: 'Threads currently waiting on this queue'
        }.freeze

        def metrics
          @metrics ||= init_metrics
        end

        def sample
          host_metrics.each do |metric_data|
            metrics[metric_data[:metric]].set(metric_data[:labels], metric_data[:value])
          end
        end

        private

        def init_metrics
          METRIC_DESCRIPTIONS.to_h do |name, description|
            [name, ::Gitlab::Metrics.gauge(:"#{METRIC_PREFIX}#{name}", description)]
          end
        end

        def host_metrics
          connection_class_metrics + replica_host_metrics
        end

        def connection_class_metrics
          Gitlab::Database.database_base_models.each_value.with_object([]) do |base_model, metrics|
            next unless base_model.connected?

            base_labels = labels_for_class(base_model)
            metrics_for_base_model = build_metrics(base_labels, base_model.connection_pool.extended_stat)

            metrics.concat(metrics_for_base_model)
          end
        end

        def replica_host_metrics
          Gitlab::Database::LoadBalancing.each_load_balancer.with_object([]) do |load_balancer, metrics|
            next if load_balancer.primary_only?

            load_balancer.host_list.hosts.each do |host|
              base_labels = labels_for_replica_host(load_balancer, host)
              metrics_for_host = build_metrics(base_labels, host.pool.extended_stat)

              metrics.concat(metrics_for_host)
            end
          end
        end

        def build_metrics(base_labels, stats)
          simple_metrics = [
            { metric: :size, labels: base_labels, value: stats[:size] },
            { metric: :connections, labels: base_labels, value: stats[:connections] },
            { metric: :idle, labels: base_labels, value: stats[:idle] },
            { metric: :waiting, labels: base_labels, value: stats[:waiting] }
          ]

          dead_metrics = split_metric_by_thread_name(:dead, base_labels, stats[:dead_by_thread_name])
          busy_metrics = split_metric_by_thread_name(:busy, base_labels, stats[:busy_by_thread_name])

          simple_metrics + dead_metrics + busy_metrics
        end

        def labels_for_class(klass)
          {
            host: klass.connection_db_config.host,
            port: klass.connection_db_config.configuration_hash[:port],
            class: klass.to_s,
            db_config_name: klass.connection_db_config.name
          }
        end

        def labels_for_replica_host(load_balancer, host)
          {
            host: host.host,
            port: host.port,
            class: load_balancer.configuration.connection_specification_name,
            db_config_name: host.pool.db_config.name
          }
        end

        def split_metric_by_thread_name(metric, base_labels, values_by_thread_name)
          values_by_thread_name = normalize_counts_by_thread_name(values_by_thread_name)
          # We want to report 0 for threads that are running but don't have a thread in the given state
          known_thread_names = Thread.list.map { |t| ThreadNameCardinalityLimiter.normalize_thread_name(t.name) }.uniq

          candidate_names = (known_thread_names + values_by_thread_name.keys).uniq

          candidate_names.each_with_object([]) do |name, metrics|
            value = values_by_thread_name[name] || 0
            metrics << { metric: metric, value: value, labels: base_labels.merge(thread_name: name) }
          end
        end

        def normalize_counts_by_thread_name(counts_by_thread_name)
          counts_by_thread_name.each_with_object(Hash.new(0)) do |(thread_name, count), result|
            result[ThreadNameCardinalityLimiter.normalize_thread_name(thread_name)] += count
          end
        end
      end
    end
  end
end

Gitlab::Metrics::Samplers::DatabaseSampler.prepend_mod_with('Gitlab::Metrics::Samplers::DatabaseSampler')
