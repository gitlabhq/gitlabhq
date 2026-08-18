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
                processor = ::Gitlab::Ci::YamlProcessor.new(@command.config_content, yaml_processor_opts)
                processor.execute
              end

              add_warnings_to_pipeline(result.warnings)

              if result.valid?
                @command.yaml_processor_result = result
              elsif empty_because_includes_filtered?(result)
                # include:rules: removed every include, leaving no jobs. That is a
                # filtering outcome, not a config error, so we must not persist a
                # failed pipeline for it.
                error(::Ci::Pipeline.rules_failure_message, failure_reason: :filtered_by_rules)
              else
                error(result.errors.first, failure_reason: :config_error)
              end

              @pipeline.config_metadata = result.config_metadata if @command.readonly?

            rescue StandardError => ex
              Gitlab::ErrorTracking.track_exception(ex,
                project_id: project.id,
                sha: @pipeline.sha
              )

              error("Undefined error (#{Labkit::Correlation::CorrelationId.current_id})",
                failure_reason: :config_error)
            end

            def break?
              @pipeline.errors.any? || @pipeline.persisted?
            end

            private

            def empty_because_includes_filtered?(result)
              Feature.enabled?(:ci_skip_pipelines_with_fully_filtered_includes, project) &&
                result.only_no_visible_jobs_error? &&
                result.any_includes_fully_filtered_by_rules?
            end

            def yaml_processor_opts
              {
                project: project,
                pipeline: @pipeline,
                sha: @pipeline.sha,
                source: @pipeline.source,
                user: current_user,
                parent_pipeline: parent_pipeline,
                pipeline_config: @command.pipeline_config,
                logger: logger,
                inputs: @command.pipeline_config.inputs_for_pipeline_creation
              }
            end

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

Gitlab::Ci::Pipeline::Chain::Config::Process.prepend_mod
