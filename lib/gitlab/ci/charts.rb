# frozen_string_literal: true

module Gitlab
  module Ci
    module Charts
      class Chart
        attr_reader :from, :to, :project

        COMPLETED_STATUSES = %i[success failed].freeze
        SELECTABLE_STATUSES = COMPLETED_STATUSES + %i[other]
        STATUSES = SELECTABLE_STATUSES + %i[all]

        def initialize(project, selected_statuses = [])
          @project = project
          @selected_statuses = selected_statuses
          @labels = []
          @totals = STATUSES.index_with { |_status| [] }
        end

        def labels
          collect if @labels.empty?

          @labels
        end

        def totals(status: :all)
          collect if @labels.empty?

          @totals[status]
        end

        private

        attr_reader :interval

        # rubocop: disable CodeReuse/ActiveRecord
        def collect
          created_at_arel = ::Ci::Pipeline.arel_table['created_at']
          pipelines_by_interval = project.all_pipelines
            .where(created_at_arel.gteq(@from))
            .where(created_at_arel.lteq(@to))
            .group("date_trunc('#{interval}', #{::Ci::Pipeline.table_name}.created_at)")

          count_by_status = totals_by_status(pipelines_by_interval)
          totals_count =
            pipelines_by_interval
              .count(:created_at)
              .transform_keys { |date| date.strftime(@format) }

          current = @from
          while current <= @to
            label = current.strftime(@format)
            @labels       << label
            @totals[:all] << (totals_count[label] || 0)
            @selected_statuses.each do |status|
              @totals[status] << (count_by_status.dig(status, label) || 0)
            end

            current += interval_step
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def totals_by_status(pipelines_by_interval)
          return {} unless @totals.slice(*SELECTABLE_STATUSES).any?

          analytics_status_grouping = COMPLETED_STATUSES.index_with { |status| status }

          counts_by_status = pipelines_by_interval
            .group(:status) # rubocop: disable CodeReuse/ActiveRecord -- this grouping is very specific to this chart
            .count(:created_at)

          # Convert hash layout from [2024-05-14 00:00:00 UTC, "failed"]=>1 to {:failed=>{"14 May"=>1}
          counts_by_status
            .group_by { |(_date, status),| analytics_status_grouping.fetch(status.to_sym, :other) }
            .transform_values do |values|
              values.to_h.transform_keys { |date,| date.strftime(@format) }
            end
        end

        def interval_step
          @interval_step ||= 1.public_send(interval) # rubocop: disable GitlabSecurity/PublicSend
        end
      end

      class YearChart < Chart
        def initialize(*)
          @to   = Date.today.end_of_month.end_of_day
          @from = (@to - 1.year).beginning_of_month.beginning_of_day
          @interval = :month
          @format = '%B %Y'

          super
        end
      end

      class MonthChart < Chart
        def initialize(*)
          @to   = Date.today.end_of_day
          @from = (@to - 1.month).beginning_of_day
          @interval = :day
          @format = '%d %B'

          super
        end
      end

      class WeekChart < Chart
        def initialize(*)
          @to   = Date.today.end_of_day
          @from = (@to - 1.week).beginning_of_day
          @interval = :day
          @format = '%d %B'

          super
        end
      end

      class PipelineTime < Chart
        def initialize(*)
          @pipeline_times = []

          super
        end

        def pipeline_times
          collect if @pipeline_times.empty?

          @pipeline_times
        end

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
