# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      class CommandLogger
        def initialize(destination: Gitlab::AppJsonLogger)
          @destination = destination
        end

        def commit(pipeline:, command:)
          return unless log?

          attributes = Gitlab::ApplicationContext.current.merge(
            "class" => self.class.name.to_s,
            "pipeline_command.source" => command.source,
            "pipeline_command.project_id" => command.project&.id,
            "pipeline_command.current_user_id" => command.current_user&.id,
            "pipeline_command.merge_request_id" => command.merge_request&.id,
            "pipeline_persisted" => pipeline.persisted?,
            "pipeline_id" => pipeline.id
          )

          attributes.compact!
          attributes.stringify_keys!

          destination.info(attributes)
        end

        private

        attr_reader :destination

        def log?
          Feature.enabled?(:ci_pipeline_command_logger_commit, Feature.current_request)
        end
      end
    end
  end
end
