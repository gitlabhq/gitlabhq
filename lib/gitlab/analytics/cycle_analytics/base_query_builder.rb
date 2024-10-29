# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class BaseQueryBuilder
        include Gitlab::CycleAnalytics::MetricsTables
        include StageQueryHelpers

        delegate :subject_class, to: :stage

        FINDER_CLASSES = {
          MergeRequest.to_s => MergeRequestsFinder,
          Issue.to_s => IssuesFinder
        }.freeze

        DEFAULT_END_EVENT_FILTER = :finished

        def initialize(stage:, params: {})
          @stage = stage
          @params = build_finder_params(params)
          @params[:state] = :opened if in_progress?
        end

        def build
          query = finder.execute
          query = stage.start_event.apply_query_customization(query)
          apply_end_event_query_customization(query)
        end

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
            finder_params[:end_event_filter] = params[:end_event_filter] || DEFAULT_END_EVENT_FILTER

            add_parent_model_params!(finder_params)
            add_time_range_params!(finder_params, params[:from], params[:to])
            finder_params.merge!(params.slice(*::Gitlab::Analytics::CycleAnalytics::RequestParams::FINDER_PARAM_NAMES))
          end
        end

        def add_parent_model_params!(finder_params)
          case stage.parent
          when Namespaces::ProjectNamespace
            finder_params[:project_id] = stage.parent.project.id
          when Project
            finder_params[:project_id] = stage.parent_id
          else
            raise(ArgumentError, "unknown parent_class: #{parent_class}")
          end
        end

        def add_time_range_params!(finder_params, from, to)
          finder_params[:created_after] = from || 30.days.ago
          finder_params[:created_before] = to if to
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def apply_end_event_query_customization(query)
          if in_progress?
            stage.end_event.apply_negated_query_customization(query)
          else
            query = stage.end_event.apply_query_customization(query)
            query.where(duration_condition)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end

Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder.prepend_mod_with('Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder')
