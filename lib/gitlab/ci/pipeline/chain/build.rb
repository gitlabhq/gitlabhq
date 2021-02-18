# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Build < Chain::Base
          include Gitlab::Allowable
          include Chain::Helpers

          def perform!
            @pipeline.assign_attributes(
              source: @command.source,
              project: @command.project,
              ref: @command.ref,
              sha: @command.sha,
              before_sha: @command.before_sha,
              source_sha: @command.source_sha,
              target_sha: @command.target_sha,
              tag: @command.tag_exists?,
              trigger_requests: Array(@command.trigger_request),
              user: @command.current_user,
              pipeline_schedule: @command.schedule,
              merge_request: @command.merge_request,
              external_pull_request: @command.external_pull_request,
              locked: @command.project.default_pipeline_lock,
              variables_attributes: variables_attributes
            )
          end

          def break?
            @pipeline.errors.any?
          end

          private

          def variables_attributes
            variables = Array(@command.variables_attributes)

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
        end
      end
    end
  end
end
