# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module ValueStreams
      class ListService
        include Gitlab::Allowable

        def initialize(parent:, current_user:, params: {})
          @parent = parent
          @current_user = current_user
          @params = params
        end

        def execute
          return forbidden unless can?(current_user, :read_cycle_analytics, parent.project)

          value_stream = ::Analytics::CycleAnalytics::ValueStream
            .build_default_value_stream(parent)

          success([value_stream])
        end

        private

        attr_reader :parent, :current_user, :params

        def success(value_streams)
          ServiceResponse.success(payload: { value_streams: value_streams })
        end

        def forbidden
          ServiceResponse.error(message: 'Forbidden', payload: {})
        end
      end
    end
  end
end

Analytics::CycleAnalytics::ValueStreams::ListService.prepend_mod
