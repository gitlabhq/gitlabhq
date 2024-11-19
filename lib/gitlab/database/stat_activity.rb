# frozen_string_literal: true

module Gitlab
  module Database
    class StatActivity
      # Keep 5 minutes worth of samples
      SAMPLING_WINDOW_SECONDS = 60 * 5

      attr_reader :connection_name

      class << self
        def write(connection_name, sample)
          new(connection_name).write(sample)
        end
      end

      def initialize(connection_name)
        @connection_name = connection_name
      end

      def write(sample)
        aggregate_sample_data(sample).each do |application, database, payload|
          update_cached_samples(application, database, payload)
        end
      end

      private

      def hash_key(application)
        "gitlab:pg_stat_sampler:#{connection_name}:#{application}:samples"
      end

      def update_cached_samples(application, database, payload)
        cached_samples = with_redis do |c|
          c.hget(hash_key(application), database)
        end

        now = Time.now.utc.to_i
        sample = {
          'created_at' => now,
          'payload' => payload
        }

        existing_samples = cached_samples ? ::Gitlab::Json.parse(cached_samples) : []
        existing_samples.append(sample)

        existing_samples = existing_samples.filter { |s| s['created_at'] > now - SAMPLING_WINDOW_SECONDS }

        with_redis do |c|
          c.hset(hash_key(application), database, ::Gitlab::Json.dump(existing_samples))
        end
      end

      def aggregate_sample_data(data)
        data
          .filter { |d| d['application'] && d['endpoint'] && d['database'] && d['state'] }
          .group_by { |c| [c['application'], c['database']] }
          .map do |group_on, inner|
            application = group_on[0]
            db_config_database = group_on[1]

            # get a map of { endpoints -> { state -> count } }
            payload = inner
              .group_by { |c| c['endpoint'] }
              .transform_values do |value|
              value.to_h { |tup| [tup['state'], tup['count']] }
            end

            [application, db_config_database, payload]
          end
      end

      def with_redis(&)
        Gitlab::Redis::SharedState.with(&)
      end
    end
  end
end
