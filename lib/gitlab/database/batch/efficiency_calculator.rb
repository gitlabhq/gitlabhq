# frozen_string_literal: true

module Gitlab
  module Database
    module Batch
      class EfficiencyCalculator
        include ::Gitlab::Utils::StrongMemoize

        DEFAULT_NUMBER_OF_JOBS = 20
        DEFAULT_EMA_ALPHA = 0.4

        def initialize(worker:)
          @worker = worker
        end

        def optimizer
          Gitlab::Database::Batch::Optimizer.new(
            current_batch_size: worker.batch_size,
            max_batch_size: worker.max_batch_size,
            time_efficiency: smoothed_time_efficiency
          )
        end
        strong_memoize_attr :optimizer

        delegate :should_optimize?, :optimized_batch_size, to: :optimizer

        private

        attr_reader :worker

        def smoothed_time_efficiency(number_of_jobs: DEFAULT_NUMBER_OF_JOBS, alpha: DEFAULT_EMA_ALPHA)
          return if job_records.size < number_of_jobs

          efficiencies = extract_valid_efficiencies(job_records)
          return if efficiencies.empty?

          dividend, divisor = calculate_weighted_sums(efficiencies, alpha)
          return if divisor == 0

          (dividend / divisor).round(2)
        end

        def job_records
          worker.jobs.successful_in_execution_order.reverse_order.limit(DEFAULT_NUMBER_OF_JOBS)
        end
        strong_memoize_attr :job_records

        def extract_valid_efficiencies(jobs)
          jobs.map(&:time_efficiency).reject(&:nil?)
        end

        # Calculates a weighted average where recent jobs count more than older ones (Exponential Moving Average).
        #
        # alpha: controls how fast older jobs lose importance (0.4 = recent jobs get 40% more weight)
        # weight: how much a job counts shrinks for older jobs (e.g., 1.0, 0.6, 0.36, ...)
        # dividend: running total of each job's efficiency multiplied by its weight
        # divisor: running total of all weights, used to divide the dividend into an average
        #
        # Returns [sum of weighted efficiencies, sum of weights] used to compute the average.
        def calculate_weighted_sums(efficiencies, alpha)
          efficiencies.each_with_index.reduce([0.0, 0.0]) do |(dividend, divisor), (job_efficiency, i)|
            weight = (1 - alpha)**i

            [dividend + (job_efficiency * weight), divisor + weight]
          end
        end
      end
    end
  end
end
