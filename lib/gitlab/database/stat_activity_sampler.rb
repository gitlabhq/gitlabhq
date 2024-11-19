# frozen_string_literal: true

module Gitlab
  module Database
    class StatActivitySampler
      include ExclusiveLeaseGuard

      # Lookup the pg_stat_get_activity(-1) function instead of pg_stat_activity table.
      # This query returns non-null `query` only for users which the connection is authorised to.
      #
      # application is either sidekiq or puma
      # endpoint refers to a worker class or a route
      # database refers to the configured database field in `config/database.yml`
      #
      # This query omits idle tuples from the pg_stat_activity table as it is only concerned with active or idle in
      # transaction processes.
      PG_STAT_ACTIVITY_SAMPLER_SQL = <<~SQL
        SELECT
          a.matches[1] AS application,
          a.matches[2] AS endpoint,
          a.matches[3] AS database,
          a.state AS state,
          COUNT(*) AS count
        FROM (
          SELECT
            state,
            regexp_matches(query, '^\\s*(?:\\/\\*(?:application:(\\w+),?)?(?:correlation_id:\\w+,?)?(?:jid:\\w+,?)?(?:endpoint_id:([\\w/\\-\\.:\\\#\\s]+),?)?(?:db_config_database:(\\w+),?)?.*?\\*\\/)?\\s*(\\w+)') AS matches
          FROM
            pg_stat_get_activity(-1)
          ) a
        GROUP BY application, endpoint, database, state
      SQL

      SAMPLING_INTERVAL = 15

      def self.sample
        Gitlab::Database::LoadBalancing.base_models.each do |bm|
          new(bm.connection).execute
        end
      end

      attr_reader :connection

      def initialize(connection)
        @connection = connection
        @lease_key = "pg_stat_sampler:#{connection.load_balancer.name}:lock"
      end

      def execute
        try_obtain_lease do
          sample = sample_pg_stat_activity
          StatActivity.write(connection.load_balancer.name, sample)
        end
      end

      private

      def lease_timeout
        SAMPLING_INTERVAL
      end

      # Overrides ExclusiveLeaseGuard to not release lease after the sample to ensure we do not oversample
      def lease_release?
        false
      end

      def sample_pg_stat_activity
        Gitlab::Database::LoadBalancing::SessionMap.current(connection.load_balancer).use_primary do
          connection.execute(PG_STAT_ACTIVITY_SAMPLER_SQL).to_a
        end
      end
    end
  end
end
