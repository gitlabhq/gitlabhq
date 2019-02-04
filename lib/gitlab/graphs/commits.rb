# frozen_string_literal: true

module Gitlab
  module Graphs
    class Commits
      attr_reader :commits, :start_date, :end_date, :duration,
        :commits_per_week_days, :commits_per_time, :commits_per_month

      def initialize(commits)
        @commits = commits
        @start_date = commits.last.committed_date.to_date
        @end_date = commits.first.committed_date.to_date
        @duration = (@end_date - @start_date).to_i

        collect_data
      end

      def authors
        @authors ||= @commits.map(&:author_email).uniq.size
      end

      def commit_per_day
        @commit_per_day ||= (@commits.size.to_f / (@duration + 1)).round(1)
      end

      def collect_data
        @commits_per_week_days = {}
        Date::DAYNAMES.each { |day| @commits_per_week_days[day] = 0 }

        @commits_per_time = {}
        (0..23).to_a.each { |hour| @commits_per_time[hour] = 0 }

        @commits_per_month = {}
        (1..31).to_a.each { |day| @commits_per_month[day] = 0 }

        @commits.each do |commit|
          hour = commit.committed_date.strftime('%k').to_i
          day_of_month = commit.committed_date.strftime('%e').to_i
          weekday = commit.committed_date.strftime('%A')

          @commits_per_week_days[weekday] ||= 0
          @commits_per_week_days[weekday] += 1
          @commits_per_time[hour] ||= 0
          @commits_per_time[hour] += 1
          @commits_per_month[day_of_month] ||= 0
          @commits_per_month[day_of_month] += 1
        end
      end
    end
  end
end
