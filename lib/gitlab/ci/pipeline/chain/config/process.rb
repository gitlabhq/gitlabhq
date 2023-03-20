# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Process < Chain::Base
            include Chain::Helpers

            def perform!
              raise ArgumentError, 'missing config content' unless @command.config_content

              result = logger.instrument(:pipeline_config_process, once: true) do
                processor = ::Gitlab::Ci::YamlProcessor.new(
                  @command.config_content, {
                    project: project,
                    pipeline: @pipeline,
                    sha: @pipeline.sha,
                    source: @pipeline.source,
                    user: current_user,
                    parent_pipeline: parent_pipeline,
                    pipeline_config: @command.pipeline_config,
                    logger: logger
                  }
                )

                processor.execute
              end

              add_warnings_to_pipeline(result.warnings)

              if result.valid?
                @command.yaml_processor_result = result
              else
                error(result.errors.first, config_error: true)
              end

              @pipeline.config_metadata = result.config_metadata

            rescue StandardError => ex
              Gitlab::ErrorTracking.track_exception(ex,
                project_id: project.id,
                sha: @pipeline.sha
              )

              error("Undefined error (#{Labkit::Correlation::CorrelationId.current_id})",
                config_error: true)
            end

            def break?
              @pipeline.errors.any? || @pipeline.persisted?
            end

            private

            def add_warnings_to_pipeline(warnings)
              return unless warnings.present?

              warnings.each { |message| warning(message) }
            end
          end
        end
      end
    end
  end
end
