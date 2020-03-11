# frozen_string_literal: true

module Gitlab
  module UsageCounters
    class Common
      class << self
        def increment(project_id)
          Gitlab::Redis::SharedState.with { |redis| redis.hincrby(base_key, project_id, 1) }
        end

        def usage_totals
          Gitlab::Redis::SharedState.with do |redis|
            total_sum = 0

            totals = redis.hgetall(base_key).each_with_object({}) do |(project_id, count), result|
              total_sum += result[project_id.to_i] = count.to_i
            end

            totals[:total] = total_sum
            totals
          end
        end

        def base_key
          raise NotImplementedError
        end
      end
    end
  end
end
