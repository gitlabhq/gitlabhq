# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Stages
      class BaseService
        include Gitlab::Allowable

        DEFAULT_VALUE_STREAM_NAME = 'default'

        def initialize(parent:, current_user:, params: {})
          @parent = parent
          @current_user = current_user
          @params = params
        end

        def execute
          raise NotImplementedError
        end

        private

        attr_reader :parent, :current_user, :params

        def success(stage, http_status = :created)
          ServiceResponse.success(payload: { stage: stage }, http_status: http_status)
        end

        def forbidden
          ServiceResponse.error(message: 'Forbidden', payload: {}, http_status: :forbidden)
        end

        def build_default_stages
          Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |stage_params|
            parent.cycle_analytics_stages.build(stage_params.merge(value_stream: value_stream))
          end
        end

        def value_stream
          @value_stream ||= params.fetch(:value_stream)
        end
      end
    end
  end
end

Analytics::CycleAnalytics::Stages::BaseService.prepend_mod_with('Analytics::CycleAnalytics::Stages::BaseService')
