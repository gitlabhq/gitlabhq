# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class BaseQueryBuilder
        include Gitlab::CycleAnalytics::MetricsTables

        delegate :subject_class, to: :stage

        FINDER_CLASSES = {
          MergeRequest.to_s => MergeRequestsFinder,
          Issue.to_s => IssuesFinder
        }.freeze

        def initialize(stage:, params: {})
          @stage = stage
          @params = build_finder_params(params)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def build
          query = finder.execute
          query = stage.start_event.apply_query_customization(query)
          query = stage.end_event.apply_query_customization(query)
          query.where(duration_condition)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        attr_reader :stage, :params

        def duration_condition
          stage.end_event.timestamp_projection.gteq(stage.start_event.timestamp_projection)
        end

        def finder
          FINDER_CLASSES.fetch(subject_class.to_s).new(params[:current_user], params)
        end

        def parent_class
          stage.parent.class
        end

        def build_finder_params(params)
          {}.tap do |finder_params|
            finder_params[:current_user] = params[:current_user]

            add_parent_model_params!(finder_params)
            add_time_range_params!(finder_params, params[:from], params[:to])
          end
        end

        def add_parent_model_params!(finder_params)
          raise(ArgumentError, "unknown parent_class: #{parent_class}") unless parent_class.eql?(Project)

          finder_params[:project_id] = stage.parent_id
        end

        def add_time_range_params!(finder_params, from, to)
          finder_params[:created_after] = from || 30.days.ago
          finder_params[:created_before] = to if to
        end
      end
    end
  end
end

Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder.prepend_if_ee('EE::Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder')
