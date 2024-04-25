# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class ValueStreamsResolver < BaseResolver
        type Types::Analytics::CycleAnalytics::ValueStreamType.connection_type, null: true

        argument :id, ID, required: false, description: 'Value stream id.'

        # ignore id in FOSS
        def resolve(id: nil)
          ::Analytics::CycleAnalytics::ValueStreams::ListService
            .new(**service_params(id: id))
            .execute
            .payload[:value_streams]
        end

        private

        def service_params(*)
          { parent: object.project_namespace, current_user: current_user, params: {} }
        end
      end
    end
  end
end

Resolvers::Analytics::CycleAnalytics::ValueStreamsResolver.prepend_mod
