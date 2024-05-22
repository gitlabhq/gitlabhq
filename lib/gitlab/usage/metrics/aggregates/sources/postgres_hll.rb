# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        module Sources
          class PostgresHll
            class << self
              def save_aggregated_metrics(metric_name:, time_period:, recorded_at_timestamp:, data:)
                unless data.is_a? ::Gitlab::Database::PostgresHll::Buckets
                  Gitlab::ErrorTracking.track_and_raise_for_dev_exception(StandardError.new("Unsupported data type: #{data.class}"))
                  return
                end

                # Usage Ping report generation for gitlab.com is very long running process
                # to make sure that saved keys are available at the end of report generation process
                # lets use triple max generation time
                keys_expiration = ::Gitlab::UsageData::MAX_GENERATION_TIME_FOR_SAAS * 3

                Gitlab::Redis::SharedState.with do |redis|
                  redis.set(
                    redis_key(metric_name: metric_name, time_period: time_period&.values&.first, recorded_at: recorded_at_timestamp),
                    data.to_json,
                    ex: keys_expiration
                  )
                end
              rescue ::Redis::CommandError => e
                Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
              end

              private

              def read_aggregated_metric(metric_name:, time_period:, recorded_at:)
                Gitlab::Redis::SharedState.with do |redis|
                  redis.get(redis_key(metric_name: metric_name, time_period: time_period, recorded_at: recorded_at))
                end
              end

              def redis_key(metric_name:, time_period:, recorded_at:)
                # add timestamp at the end of the key to avoid stale keys if
                # usage ping job is retried
                "#{metric_name}_#{time_period_to_human_name(time_period)}-#{recorded_at.to_i}"
              end

              def time_period_to_human_name(time_period)
                return Gitlab::Usage::TimeFrame::ALL_TIME_TIME_FRAME_NAME if time_period.blank?

                start_date = time_period.first.to_date
                end_date = time_period.last.to_date

                if (end_date - start_date).to_i > 7
                  Gitlab::Usage::TimeFrame::TWENTY_EIGHT_DAYS_TIME_FRAME_NAME
                else
                  Gitlab::Usage::TimeFrame::SEVEN_DAYS_TIME_FRAME_NAME
                end
              end
            end
          end
        end
      end
    end
  end
end
