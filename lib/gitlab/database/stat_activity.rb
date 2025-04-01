# frozen_string_literal: true

module Gitlab
  module Database
    class StatActivity
      # Keep 5 minutes worth of samples
      SAMPLING_WINDOW_SECONDS = 60 * 5

      attr_reader :connection_name

      # This class maintains a hash in Redis per database connection (main) and per application (sidekiq, web).
      # The hash contains a key per database name `gitlabhq_production_sidekiq`, `gitlabhq_production_sidekiq_urgent`
      # The payload of each entry in the hash is a json array with samples.
      #
      # The whole hash from Redis looks like this:
      # key: gitlab:pg_stat_sampler:main:sidekiq:samples
      # {
      #   "gitlabhq_production_sidekiq": [
      #     // a sample
      #     {
      #       "created_at": 1732543621,
      #       "payload": {
      #         "DetectRepositoryLanguagesWorker": {
      #           "idle in transaction": 1
      #         },
      #         "ContainerRegistry::RecordDataRepairDetailWorker": {
      #           "idle": 1,
      #           "active": 2
      #         }
      #       }
      #     }
      #   ]
      # }

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

      # Returns the total of non-idle connections aggregated from the last `min_samples`
      # for each database name, eg `gitlabhq_production_sidekiq`, `gitlabhq_production_sidekiq_urgent`.
      # Hash for each database will be empty if there are not enough samples in Redis to meet `min_samples`.
      #
      # Returns {
      #   "gitlabhq_production_sidekiq": {
      #     "WorkerA": 1,
      #     "WorkerB": 2
      #   },
      #   gitlabhq_production_sidekiq_urgent: {
      #     "WorkerC": 3
      #   }
      # }
      def non_idle_connections_by_db(min_samples)
        result = {}
        samples_by_db.each do |db, samples|
          result[db] = {}
          parsed_samples = Gitlab::Json.parse(samples)

          next if parsed_samples.length < min_samples

          result[db] = parsed_samples.last(min_samples)
                                     .map { |sample| non_idle_by_endpoints(sample) }
                                     .reduce({}) do |res, hash|
                                       res.merge(hash) { |_key, old_val, new_val| old_val + new_val }
                                     end
        end

        result
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

      def samples_by_db
        with_redis { |c| c.hgetall(hash_key(Gitlab.process_name)) }
      end

      def non_idle_by_endpoints(sample)
        sample["payload"].transform_values do |states|
          states.reject { |state, _count| state == "idle" }.values.sum
        end
      end

      def with_redis(&)
        Gitlab::Redis::SharedState.with(&)
      end
    end
  end
end
