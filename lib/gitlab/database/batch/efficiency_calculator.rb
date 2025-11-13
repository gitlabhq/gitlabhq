# frozen_string_literal: true

module Gitlab
  module Database
    module Batch
      class EfficiencyCalculator
        include ::Gitlab::Utils::StrongMemoize

        DEFAULT_NUMBER_OF_JOBS = 20
        DEFAULT_EMA_ALPHA = 0.4

        def initialize(record:)
          @record = record
        end

        def optimizer
          Gitlab::Database::Batch::Optimizer.new(
            current_batch_size: record.batch_size,
            max_batch_size: record.max_batch_size,
            time_efficiency: smoothed_time_efficiency
          )
        end
        strong_memoize_attr :optimizer

        delegate :should_optimize?, :optimized_batch_size, to: :optimizer

        private

        attr_reader :record

        def smoothed_time_efficiency(number_of_jobs: DEFAULT_NUMBER_OF_JOBS, alpha: DEFAULT_EMA_ALPHA)
          return if job_records.size < number_of_jobs

          efficiencies = extract_valid_efficiencies(job_records)
          return if efficiencies.empty?

          dividend, divisor = calculate_weighted_sums(efficiencies, alpha)
          return if divisor == 0

          (dividend / divisor).round(2)
        end

        def job_records
          record.jobs.successful_in_execution_order.reverse_order.limit(DEFAULT_NUMBER_OF_JOBS).with_preloads
        end

        def extract_valid_efficiencies
          record.jobs.map(&:time_efficiency).reject(&:nil?).each_with_index
        end

        def calculate_weighted_sums(efficiencies, alpha)
          efficiencies.each_with_object([0, 0]) do |(_job_eff, i), (_dividend, divisor)|
            weight = (1 - alpha)**i

            divisor + weight
          end
        end
      end
    end
  end
end
