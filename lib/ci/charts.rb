module Ci
  module Charts
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


      def push(from, to, format)
        @labels << from.strftime(format)
        @total << project.builds.
          where("? > #{Ci::Build.table_name}.created_at AND #{Ci::Build.table_name}.created_at > ?", to, from).
          count(:all)
        @success << project.builds.
          where("? > #{Ci::Build.table_name}.created_at AND #{Ci::Build.table_name}.created_at > ?", to, from).
          success.count(:all)
      end
    end

    class YearChart < Chart
      def collect
        13.times do |i|
          start_month = (Date.today.years_ago(1) + i.month).beginning_of_month
          end_month = start_month.end_of_month

          push(start_month, end_month, "%d %B %Y")
        end
      end
    end

    class MonthChart < Chart
      def collect
        30.times do |i|
          start_day = Date.today - 30.days + i.days
          end_day = Date.today - 30.days + i.day + 1.day

          push(start_day, end_day, "%d %B")
        end
      end
    end

    class WeekChart < Chart
      def collect
        7.times do |i|
          start_day = Date.today - 7.days + i.days
          end_day = Date.today - 7.days + i.day + 1.day

          push(start_day, end_day, "%d %B")
        end
      end
    end

    class BuildTime < Chart
      def collect
        commits = project.commits.joins(:builds).where("#{Ci::Build.table_name}.finished_at is NOT NULL AND #{Ci::Build.table_name}.started_at is NOT NULL").last(30)
        commits.each do |commit|
          @labels << commit.short_sha
          @build_times << (commit.duration / 60)
        end
      end
    end
  end
end
