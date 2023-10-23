# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Context
        class Build < Base
          include Gitlab::Utils::StrongMemoize

          attr_reader :attributes

          def initialize(pipeline, attributes = {})
            super(pipeline)

            @attributes = attributes
          end

          def variables
            stub_build.scoped_variables
          end
          strong_memoize_attr :variables

          private

          def stub_build
            # This is a temporary piece of technical debt to allow us access
            # to the CI variables to evaluate rules before we persist a Build
            # with the result. We should refactor away the extra Build.new,
            # but be able to get CI Variables directly from the Seed::Build.
            ::Ci::Build.new(build_attributes)
          end

          # Assigning tags and needs is slow and they are not needed for rules
          # evaluation since we don't use them to compute the variables at this point.
          def build_attributes
            attributes
              .except(:tag_list, :needs_attributes)
              .merge!(pipeline_attributes, ci_stage_attributes)
          end

          def ci_stage_attributes
            {
              ci_stage: ::Ci::Stage.new(
                name: attributes[:stage],
                position: attributes[:stage_idx],
                pipeline: pipeline_attributes[:pipeline],
                project: pipeline_attributes[:project]
              )
            }
          end
        end
      end
    end
  end
end
