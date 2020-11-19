# frozen_string_literal: true

module Gitlab
  module Ci
    module Charts
      class Chart
        attr_reader :from, :to, :labels, :total, :success, :project, :pipeline_times

        def initialize(project)
          @labels = []
          @total = []
          @success = []
          @pipeline_times = []
          @project = project

          collect
        end

        private

        attr_reader :interval

        # rubocop: disable CodeReuse/ActiveRecord
        def collect
          query = project.all_pipelines
            .where(::Ci::Pipeline.arel_table['created_at'].gteq(@from))
            .where(::Ci::Pipeline.arel_table['created_at'].lteq(@to))

          totals_count  = grouped_count(query)
          success_count = grouped_count(query.success)

          current = @from
          while current <= @to
            @labels  << current.strftime(@format)
            @total   << (totals_count[current] || 0)
            @success << (success_count[current] || 0)

            current += interval_step
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def grouped_count(query)
          query
            .group("date_trunc('#{interval}', #{::Ci::Pipeline.table_name}.created_at)")
            .count(:created_at)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def interval_step
          @interval_step ||= 1.public_send(interval) # rubocop: disable GitlabSecurity/PublicSend
        end
      end

      class YearChart < Chart
        def initialize(*)
          @to     = Date.today.end_of_month.end_of_day
          @from   = (@to - 1.year).beginning_of_month.beginning_of_day
          @interval = :month
          @format = '%B %Y'

          super
        end
      end

      class MonthChart < Chart
        def initialize(*)
          @to     = Date.today.end_of_day
          @from   = (@to - 1.month).beginning_of_day
          @interval = :day
          @format = '%d %B'

          super
        end
      end

      class WeekChart < Chart
        def initialize(*)
          @to     = Date.today.end_of_day
          @from   = (@to - 1.week).beginning_of_day
          @interval = :day
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
