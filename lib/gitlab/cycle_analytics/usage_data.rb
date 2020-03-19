# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class UsageData
      include Gitlab::Utils::StrongMemoize
      PROJECTS_LIMIT = 10

      attr_reader :options

      def initialize
        @options = { from: 7.days.ago }
      end

      def projects
        strong_memoize(:projects) do
          projects = Project.where.not(last_activity_at: nil).order(last_activity_at: :desc).limit(10) +
                     Project.where.not(last_repository_updated_at: nil).order(last_repository_updated_at: :desc).limit(10)

          projects = projects.uniq.sort_by do |project|
            [project.last_activity_at, project.last_repository_updated_at].min
          end

          if projects.size < 10
            projects.concat(Project.where(last_activity_at: nil, last_repository_updated_at: nil).limit(10))
          end

          projects.uniq.first(10)
        end
      end

      def to_json(*)
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
          ::CycleAnalytics::ProjectLevel.new(project, options: options).all_medians_by_stage.each do |stage_name, median|
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
