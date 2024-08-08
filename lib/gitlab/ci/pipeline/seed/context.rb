# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Context
          attr_reader :pipeline, :root_variables, :logger, :execution_configs

          def initialize(pipeline, root_variables: [], logger: nil)
            @pipeline = pipeline
            @root_variables = root_variables
            @logger = logger || build_logger
            @execution_configs = {}
          end

          def find_or_build_execution_config(attributes)
            @execution_configs[attributes] ||= ::Ci::BuildExecutionConfig.new(
              attributes.merge(
                project: @pipeline.project,
                pipeline: @pipeline
              )
            )
          end

          private

          def build_logger
            ::Gitlab::Ci::Pipeline::Logger.new(project: pipeline.project)
          end
        end
      end
    end
  end
end
