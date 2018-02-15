module Gitlab
  module CycleAnalytics
    class UsageData
      PROJECTS_LIMIT = 10

      attr_reader :projects, :options

      def initialize
        @projects = Project.sorted_by_activity.limit(PROJECTS_LIMIT)
        @options = { from: 7.days.ago }
      end

      def to_json
        total = 0

        values =
          medians_per_stage.each_with_object({}) do |(stage_name, medians), hsh|
            calculations = stage_values(medians)

            total += calculations.values.compact.sum
            hsh[stage_name] = calculations
          end

        values[:total] = total

        { avg_cycle_analytics: values }
      end

      private

      def medians_per_stage
        projects.each_with_object({}) do |project, hsh|
          ::CycleAnalytics.new(project, options).all_medians_per_stage.each do |stage_name, median|
            hsh[stage_name] ||= []
            hsh[stage_name] << median
          end
        end
      end

      def stage_values(medians)
        medians = medians.map(&:presence).compact
        average = calc_average(medians)

        {
          average: average,
          sd: standard_deviation(medians, average),
          missing: projects.length - medians.length
        }
      end

      def calc_average(values)
        return if values.empty?

        (values.sum / values.length).to_i
      end

      def standard_deviation(values, average)
        Math.sqrt(sample_variance(values, average)).to_i
      end

      def sample_variance(values, average)
        return 0 if values.length <= 1

        sum = values.inject(0) do |acc, val|
          acc + (val - average)**2
        end

        sum / (values.length - 1)
      end
    end
  end
end
