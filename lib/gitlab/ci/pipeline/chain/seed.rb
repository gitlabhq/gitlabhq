# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Seed < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            raise ArgumentError, 'missing YAML processor result' unless @command.yaml_processor_result
            raise ArgumentError, 'missing workflow rules result' unless @command.workflow_rules_result

            # Allocate next IID. This operation must be outside of transactions of pipeline creations.
            logger.instrument(:pipeline_allocate_seed_attributes, once: true) do
              pipeline.ensure_project_iid! unless @command.readonly?
              pipeline.ensure_ci_ref!
            end

            # Protect the pipeline. This is assigned in Populate instead of
            # Build to prevent erroring out on ambiguous refs.
            pipeline.protected = @command.protected_ref?

            ##
            # Gather all runtime build/stage errors
            #
            seed_errors = logger.instrument(:pipeline_seed_evaluation, once: true) do
              pipeline_seed.errors
            end

            log_swallowed_rule_errors(seed_errors)

            return error(seed_errors.join("\n"), failure_reason: :config_error) if seed_errors

            @command.pipeline_seed = pipeline_seed
          end

          def break?
            pipeline.errors.any?
          end

          private

          # Measures https://gitlab.com/gitlab-org/gitlab/-/issues/606330 before changing behaviour:
          # these errors are currently discarded, so `would_newly_fail` counts the pipelines that
          # would start failing if we surfaced them.
          def log_swallowed_rule_errors(seed_errors)
            return if @command.readonly?

            excluded_errors = pipeline_seed.excluded_stage_errors
            return unless excluded_errors

            Gitlab::AppJsonLogger.info(
              class_name: self.class.name,
              message: 'rule errors dropped with fully excluded stage',
              project_id: project.id,
              extra: {
                pipeline_source: @command.source.to_s,
                would_newly_fail: seed_errors.nil?,
                dropped_errors: excluded_errors
              }
            )
          end

          def pipeline_seed
            logger.instrument(:pipeline_seed_initialization, once: true) do
              stages_attributes = logger.instrument(:pipeline_seed_initialization_stages_attributes, once: true) do
                @command.yaml_processor_result.stages_attributes
              end

              Gitlab::Ci::Pipeline::Seed::Pipeline.new(context, stages_attributes)
            end
          end
          strong_memoize_attr :pipeline_seed

          def context
            Gitlab::Ci::Pipeline::Seed::Context.new(
              pipeline,
              root_variables: root_variables,
              logger: logger
            )
          end

          def root_variables
            ::Gitlab::Ci::Variables::Helpers.merge_variables(
              @command.yaml_processor_result.root_variables,
              @command.workflow_rules_result.variables)
          end
          strong_memoize_attr :root_variables
        end
      end
    end
  end
end
