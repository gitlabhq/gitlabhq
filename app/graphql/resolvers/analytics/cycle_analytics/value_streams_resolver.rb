# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class ValueStreamsResolver < BaseResolver
        type Types::Analytics::CycleAnalytics::ValueStreamType.connection_type, null: true

        def resolve
          # FOSS only have default value stream available
          [
            ::Analytics::CycleAnalytics::ValueStream.build_default_value_stream(object.project_namespace)
          ]
        end
      end
    end
  end
end

Resolvers::Analytics::CycleAnalytics::ValueStreamsResolver.prepend_mod
