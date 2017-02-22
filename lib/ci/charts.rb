module Ci
  module Charts
    module DailyInterval
      def grouped_count(query)
        query.
          group("DATE(#{Ci::Build.table_name}.created_at)").
          count(:created_at).
          transform_keys { |date| date.strftime(@format) }
      end

      def interval_step
        @interval_step ||= 1.day
      end
    end

    module MonthlyInterval
      def grouped_count(query)
        if Gitlab::Database.postgresql?
          query.
            group("to_char(#{Ci::Build.table_name}.created_at, '01 Month YYYY')").
            count(:created_at).
            transform_keys(&:squish)
        else
          query.
            group("DATE_FORMAT(#{Ci::Build.table_name}.created_at, '01 %M %Y')").
            count(:created_at)
        end
      end

      def interval_step
        @interval_step ||= 1.month
      end
    end

    class Chart
      attr_reader :labels, :total, :success, :project, :build_times

      def initialize(project)
        @labels = []
        @total = []
        @success = []
        @build_times = []
        @project = project

        collect
      end

      def collect
        query = project.builds.
          where("? > #{Ci::Build.table_name}.created_at AND #{Ci::Build.table_name}.created_at > ?", @to, @from)

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
    end

    class YearChart < Chart
      include MonthlyInterval

      def initialize(*)
        @to     = Date.today.end_of_month
        @from   = @to.years_ago(1).beginning_of_month
        @format = '%d %B %Y'

        super
      end
    end

    class MonthChart < Chart
      include DailyInterval

      def initialize(*)
        @to     = Date.today
        @from   = @to - 30.days
        @format = '%d %B'

        super
      end
    end

    class WeekChart < Chart
      include DailyInterval

      def initialize(*)
        @to     = Date.today
        @from   = @to - 7.days
        @format = '%d %B'

        super
      end
    end

    class BuildTime < Chart
      def collect
        commits = project.pipelines.last(30)

        commits.each do |commit|
          @labels << commit.short_sha
          duration = commit.duration || 0
          @build_times << (duration / 60)
        end
      end
    end
  end
end
