# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class StagesResolver < BaseResolver
        type [Types::Analytics::CycleAnalytics::ValueStreams::StageType], null: true

        def resolve
          response =
            ::Analytics::CycleAnalytics::Stages::ListService.new(
              parent: namespace,
              current_user: current_user,
              params: { value_stream: object }
            ).execute

          response[:stages]
        end

        def namespace
          object.project.project_namespace
        end
      end
    end
  end
end

Resolvers::Analytics::CycleAnalytics::StagesResolver.prepend_mod
