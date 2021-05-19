# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Stages
      class ListService < Analytics::CycleAnalytics::Stages::BaseService
        def execute
          return forbidden unless allowed?

          success(build_default_stages)
        end

        private

        def allowed?
          can?(current_user, :read_cycle_analytics, parent)
        end

        def success(stages)
          ServiceResponse.success(payload: { stages: stages })
        end
      end
    end
  end
end

Analytics::CycleAnalytics::Stages::ListService.prepend_mod_with('Analytics::CycleAnalytics::Stages::ListService')
