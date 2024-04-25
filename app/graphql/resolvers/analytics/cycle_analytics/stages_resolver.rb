# frozen_string_literal: true

module Resolvers
  module Analytics
    module CycleAnalytics
      class StagesResolver < BaseResolver
        type [Types::Analytics::CycleAnalytics::ValueStreams::StageType], null: true

        argument :id, ID, required: false, description: 'Value stream stage id.'

        def resolve(id: nil)
          list_stages(stage_params(id: id).merge(value_stream: object))
        end

        private

        def list_stages(list_service_params)
          ::Analytics::CycleAnalytics::Stages::ListService.new(
            parent: namespace,
            current_user: current_user,
            params: list_service_params
          ).execute[:stages]
        end

        def namespace
          object.project.project_namespace
        end

        def stage_params(id: nil)
          list_params = {}
          list_params[:stage_ids] = [::GitlabSchema.parse_gid(id).model_id] if id
          list_params
        end
      end
    end
  end
end

Resolvers::Analytics::CycleAnalytics::StagesResolver.prepend_mod
