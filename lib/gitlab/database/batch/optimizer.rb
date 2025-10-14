# frozen_string_literal: true

module Gitlab
  module Database
    module Batch
      # This is an optimizer for throughput of batched jobs
      #
      # The underyling mechanic is based on the concept of time efficiency:
      #     time efficiency = job duration / interval
      # Ideally, this is close but lower than 1 - so we're using time efficiently.
      #
      # We aim to land in the 90%-98% range, which gives the database a little breathing room
      # in between.
      #
      # The optimizer is based on calculating the exponential moving average of time efficiencies
      # for the last N jobs. If we're outside the range, we add 10% to or decrease by 20% of the batch size.
      class Optimizer
        # Target time efficiency for a job
        # Time efficiency is defined as: job duration / interval
        TARGET_EFFICIENCY = (0.9..0.95)

        # Lower and upper bound for the batch size
        MIN_BATCH_SIZE = 1_000
        MAX_BATCH_SIZE = 2_000_000

        # Limit for the multiplier of the batch size
        MAX_MULTIPLIER = 1.2

        attr_reader :current_batch_size, :max_batch_size, :time_efficiency

        def initialize(current_batch_size:, max_batch_size: nil, time_efficiency: nil)
          @current_batch_size = current_batch_size
          @max_batch_size = max_batch_size
          @time_efficiency = time_efficiency
        end

        def optimized_batch_size
          multiplier = calculate_multiplier
          new_size = (current_batch_size * multiplier).to_i

          apply_limits(new_size)
        end

        def should_optimize?
          return false if time_efficiency.nil? || time_efficiency == 0

          TARGET_EFFICIENCY.exclude?(time_efficiency)
        end

        private

        # Assumption: time efficiency is linear in the batch size
        def calculate_multiplier
          [TARGET_EFFICIENCY.max / time_efficiency, MAX_MULTIPLIER].min
        end

        def apply_limits(new_size)
          max_limit = max_batch_size || MAX_BATCH_SIZE
          min_limit = [max_limit, MIN_BATCH_SIZE].min

          new_size.clamp(min_limit, max_limit)
        end
      end
    end
  end
end
