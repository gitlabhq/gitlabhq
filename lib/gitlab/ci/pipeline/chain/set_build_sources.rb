# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class SetBuildSources < Chain::Base
          def perform!
            command.pipeline_seed.stages.each do |stage|
              stage.statuses.each do |job|
                job_source = if pipeline_execution_policy_build?(job)
                               'pipeline_execution_policy'
                             elsif scan_execution_policy_build?(job)
                               'scan_execution_policy'
                             else
                               pipeline.source
                             end

                job.build_job_source(source: job_source, project_id: project.id)
              end
            end
          end

          def break?
            pipeline.errors.any?
          end

          private

          # Overridden in EE
          def pipeline_execution_policy_build?(_build)
            false
          end

          # Overridden in EE
          def scan_execution_policy_build?(_build)
            false
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::SetBuildSources.prepend_mod_with('Gitlab::Ci::Pipeline::Chain::SetBuildSources')
