# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Build
          class Associations < Chain::Base
            include Gitlab::Allowable
            include Chain::Helpers

            def perform!
              assign_pipeline_variables
              assign_source_pipeline
            end

            def break?
              @pipeline.errors.any?
            end

            private

            def assign_pipeline_variables
              @pipeline.variables_attributes = variables_attributes
            end

            def assign_source_pipeline
              return unless @command.bridge

              @pipeline.build_source_pipeline(
                source_pipeline: @command.bridge.pipeline,
                source_project: @command.bridge.project,
                source_bridge: @command.bridge,
                project: @command.project,
                source_partition_id: @command.bridge.partition_id
              )
            end

            def variables_attributes
              variables = Array(@command.variables_attributes)
              variables = apply_permissions(variables)
              validate_uniqueness(variables)
            end

            def apply_permissions(variables)
              # On demand DAST validation pipelines are created by the GitLab backend.
              # Their pipeline variables are also controlled by GitLab.
              # See https://gitlab.com/gitlab-org/gitlab/-/issues/513148
              return variables if @command.source.to_sym == :ondemand_dast_validation

              # We allow parent pipelines to pass variables to child pipelines since
              # these variables are coming from internal configurations. We will check
              # permissions to :set_pipeline_variables when those are injected upstream,
              # to the parent pipeline.
              # In other scenarios (e.g. multi-project pipelines or run pipeline via UI)
              # the variables are provided from the outside and those should be guarded.
              return variables if @command.creates_child_pipeline?

              if variables.present? && !can?(@command.current_user, :set_pipeline_variables, @command.project)
                error("Insufficient permissions to set pipeline variables")
                variables = []
              end

              variables
            end

            def validate_uniqueness(variables)
              duplicated_keys = variables
                .map { |var| var[:key] } # rubocop: disable Rails/Pluck -- Pluck raises error too
                .tally
                .filter_map { |key, count| key if count > 1 }

              if duplicated_keys.empty?
                variables
              else
                error(duplicate_variables_message(duplicated_keys), failure_reason: :config_error)
                []
              end
            end

            def duplicate_variables_message(keys)
              "Duplicate variable #{'name'.pluralize(keys.size)}: #{keys.join(', ')}"
            end
          end
        end
      end
    end
  end
end
