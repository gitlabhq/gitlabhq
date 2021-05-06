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

              result = ::Gitlab::Ci::YamlProcessor.new(
                @command.config_content, {
                  project: project,
                  ref: @pipeline.ref,
                  sha: @pipeline.sha,
                  source: @pipeline.source,
                  user: current_user,
                  parent_pipeline: parent_pipeline
                }
              ).execute

              add_warnings_to_pipeline(result.warnings)

              if result.valid?
                @command.yaml_processor_result = result
              else
                error(result.errors.first, config_error: true)
              end

              @pipeline.merged_yaml = result.merged_yaml

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
