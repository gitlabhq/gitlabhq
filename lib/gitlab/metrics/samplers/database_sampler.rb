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
          host_stats.each do |host_stat|
            METRIC_DESCRIPTIONS.each_key do |metric|
              metrics[metric].set(host_stat[:labels], host_stat[:stats][metric])
            end
          end
        end

        private

        def init_metrics
          METRIC_DESCRIPTIONS.to_h do |name, description|
            [name, ::Gitlab::Metrics.gauge(:"#{METRIC_PREFIX}#{name}", description)]
          end
        end

        def host_stats
          connection_class_stats + replica_host_stats
        end

        def connection_class_stats
          Gitlab::Database.database_base_models.each_value.with_object([]) do |base_model, stats|
            next unless base_model.connected?

            stats << { labels: labels_for_class(base_model), stats: base_model.connection_pool.stat }
          end
        end

        def replica_host_stats
          Gitlab::Database::LoadBalancing.each_load_balancer.with_object([]) do |load_balancer, stats|
            next if load_balancer.primary_only?

            load_balancer.host_list.hosts.each do |host|
              stats << { labels: labels_for_replica_host(load_balancer, host), stats: host.pool.stat }
            end
          end
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
      end
    end
  end
end

Gitlab::Metrics::Samplers::DatabaseSampler.prepend_mod_with('Gitlab::Metrics::Samplers::DatabaseSampler')
