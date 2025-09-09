# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Context
        class Global < Base
          include Gitlab::Utils::StrongMemoize

          def initialize(pipeline, yaml_variables:)
            super(pipeline)

            @yaml_variables = yaml_variables.to_a
          end

          def variables
            strong_memoize(:variables) do
              # This is a temporary piece of technical debt to allow us access
              # to the CI variables to evaluate workflow:rules
              # with the result. We should refactor away the extra Build.new,
              # but be able to get CI Variables directly from the Seed::Build.
              stub_build.scoped_variables.reject { |var| var[:key] =~ /\ACI_(JOB|BUILD)/ }
            end
          end

          private

          def stub_build
            if Feature.enabled?(:read_from_new_ci_destinations, project)
              ::Ci::Build.new(pipeline_attributes).tap do |job|
                temp_job_definition = ::Ci::JobDefinition.fabricate(
                  config: { yaml_variables: @yaml_variables },
                  project_id: pipeline.project_id,
                  partition_id: pipeline.partition_id
                )
                job.temp_job_definition = temp_job_definition
              end
            else
              ::Ci::Build.new(build_attributes)
            end
          end

          # Remove this method with FF `read_from_new_ci_destinations`
          def build_attributes
            pipeline_attributes.merge(
              yaml_variables: @yaml_variables)
          end
        end
      end
    end
  end
end
