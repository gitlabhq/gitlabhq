module Gitlab
  module CycleAnalytics
    class UsageData
      PROJECTS_LIMIT = 10

      attr_reader :projects, :options

      def initialize(projects, options)
        @projects = projects
        @options = options
      end

      def to_json
        total = 0
        values = {}

        medians_per_stage.each do |stage_name, medians|
          medians = medians.map(&:presence).compact

          stage_values = {
            average: calc_average(medians),
            sd: standard_deviation(medians),
            missing: projects.length - medians.length
          }

          total += stage_values.values.compact.sum
          values[stage_name] = stage_values
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

      def calc_average(values)
        return if values.empty?

        (values.sum / values.length).to_i
      end

      def sample_variance(values)
        return 0 if values.length <= 1

        avg = calc_average(values)
        sum = values.inject(0) do |acc, val|
          acc + (val - avg)**2
        end

        sum / (values.length - 1)
      end

      def standard_deviation(values)
        Math.sqrt(sample_variance(values)).to_i
      end
    end
  end
end
