# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class BaseQueryBuilder
        include Gitlab::CycleAnalytics::MetricsTables

        delegate :subject_class, to: :stage

        # rubocop: disable CodeReuse/ActiveRecord

        def initialize(stage:, params: {})
          @stage = stage
          @params = params
        end

        def build
          query = subject_class
          query = filter_by_parent_model(query)
          query = filter_by_time_range(query)
          query = stage.start_event.apply_query_customization(query)
          query = stage.end_event.apply_query_customization(query)
          query.where(duration_condition)
        end

        private

        attr_reader :stage, :params

        def duration_condition
          stage.end_event.timestamp_projection.gteq(stage.start_event.timestamp_projection)
        end

        def filter_by_parent_model(query)
          if parent_class.eql?(Project)
            if subject_class.eql?(Issue)
              query.where(project_id: stage.parent_id)
            elsif subject_class.eql?(MergeRequest)
              query.where(target_project_id: stage.parent_id)
            else
              raise ArgumentError, "unknown subject_class: #{subject_class}"
            end
          else
            raise ArgumentError, "unknown parent_class: #{parent_class}"
          end
        end

        def filter_by_time_range(query)
          from = params.fetch(:from, 30.days.ago)
          to = params[:to]

          query = query.where(subject_table[:created_at].gteq(from))
          query = query.where(subject_table[:created_at].lteq(to)) if to
          query
        end

        def subject_table
          subject_class.arel_table
        end

        def parent_class
          stage.parent.class
        end

        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
