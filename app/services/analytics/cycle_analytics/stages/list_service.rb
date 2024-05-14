# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Stages
      class ListService < Analytics::CycleAnalytics::Stages::BaseService
        def execute
          return forbidden unless allowed?

          stages = build_default_stages
          # In FOSS, stages are not persisted, we match them by name
          stages = stages.select { |stage| params[:stage_ids].include?(stage.name) } if filter_by_stage_ids?
          success(stages)
        end

        private

        def allowed?
          can?(current_user, :read_cycle_analytics, parent.project)
        end

        def success(stages)
          ServiceResponse.success(payload: { stages: stages })
        end

        def filter_by_stage_ids?
          params[:stage_ids].present?
        end
      end
    end
  end
end

Analytics::CycleAnalytics::Stages::ListService.prepend_mod_with('Analytics::CycleAnalytics::Stages::ListService')
