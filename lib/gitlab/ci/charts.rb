# frozen_string_literal: true

module Gitlab
  module Ci
    module Charts
      module DailyInterval
        # rubocop: disable CodeReuse/ActiveRecord
        def grouped_count(query)
          query
            .group("DATE(#{::Ci::Pipeline.table_name}.created_at)")
            .count(:created_at)
            .transform_keys { |date| date.strftime(@format) } # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def interval_step
          @interval_step ||= 1.day
        end
      end

      module MonthlyInterval
        # rubocop: disable CodeReuse/ActiveRecord
        def grouped_count(query)
          query
            .group("to_char(#{::Ci::Pipeline.table_name}.created_at, '01 Month YYYY')")
            .count(:created_at)
            .transform_keys(&:squish)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def interval_step
          @interval_step ||= 1.month
        end
      end

      class Chart
        attr_reader :labels, :total, :success, :project, :pipeline_times

        def initialize(project)
          @labels = []
          @total = []
          @success = []
          @pipeline_times = []
          @project = project

          collect
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def collect
          query = project.all_pipelines
            .where("? > #{::Ci::Pipeline.table_name}.created_at AND #{::Ci::Pipeline.table_name}.created_at > ?", @to, @from) # rubocop:disable GitlabSecurity/SqlInjection

          totals_count  = grouped_count(query)
          success_count = grouped_count(query.success)

          current = @from
          while current < @to
            label = current.strftime(@format)

            @labels  << label
            @total   << (totals_count[label] || 0)
            @success << (success_count[label] || 0)

            current += interval_step
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end

      class YearChart < Chart
        include MonthlyInterval
        attr_reader :to, :from

        def initialize(*)
          @to     = Date.today.end_of_month.end_of_day
          @from   = @to.years_ago(1).beginning_of_month.beginning_of_day
          @format = '%d %B %Y'

          super
        end
      end

      class MonthChart < Chart
        include DailyInterval
        attr_reader :to, :from

        def initialize(*)
          @to     = Date.today.end_of_day
          @from   = 1.month.ago.beginning_of_day
          @format = '%d %B'

          super
        end
      end

      class WeekChart < Chart
        include DailyInterval
        attr_reader :to, :from

        def initialize(*)
          @to     = Date.today.end_of_day
          @from   = 1.week.ago.beginning_of_day
          @format = '%d %B'

          super
        end
      end

      class PipelineTime < Chart
        def collect
          commits = project.all_pipelines.last(30)

          commits.each do |commit|
            @labels << commit.short_sha
            duration = commit.duration || 0
            @pipeline_times << (duration / 60)
          end
        end
      end
    end
  end
end
