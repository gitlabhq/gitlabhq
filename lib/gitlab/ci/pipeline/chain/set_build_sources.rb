# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class SetBuildSources < Chain::Base
          def perform!
            return unless Feature.enabled?(:populate_and_use_build_source_table, project)

            command.pipeline_seed.stages.each do |stage|
              stage.statuses.each do |build|
                next unless build.instance_of?(::Ci::Build)

                build_source = if pipeline_execution_policy_build?(build)
                                 'pipeline_execution_policy'
                               elsif scan_execution_policy_build?(build)
                                 'scan_execution_policy'
                               else
                                 pipeline.source
                               end

                build.build_build_source(source: build_source,
                  project_id: project.id)
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
