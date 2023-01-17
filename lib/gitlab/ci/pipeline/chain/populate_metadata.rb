# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class PopulateMetadata < Chain::Base
          include Chain::Helpers

          def perform!
            set_pipeline_name
            return if pipeline.pipeline_metadata.nil? || pipeline.pipeline_metadata.valid?

            message = pipeline.pipeline_metadata.errors.full_messages.join(', ')
            error("Failed to build pipeline metadata! #{message}")
          end

          def break?
            pipeline.pipeline_metadata&.errors&.any?
          end

          private

          def set_pipeline_name
            return if @command.yaml_processor_result.workflow_name.blank?

            name = @command.yaml_processor_result.workflow_name
            name = ExpandVariables.expand(name, -> { global_context.variables.sort_and_expand_all })

            return if name.blank?

            pipeline.build_pipeline_metadata(project: pipeline.project, name: name.strip)
          end

          def global_context
            Gitlab::Ci::Build::Context::Global.new(
              pipeline, yaml_variables: @command.pipeline_seed.root_variables)
          end
        end
      end
    end
  end
end
