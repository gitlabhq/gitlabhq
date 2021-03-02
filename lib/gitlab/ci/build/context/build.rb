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
            strong_memoize(:variables) do
              # This is a temporary piece of technical debt to allow us access
              # to the CI variables to evaluate rules before we persist a Build
              # with the result. We should refactor away the extra Build.new,
              # but be able to get CI Variables directly from the Seed::Build.
              stub_build.scoped_variables
            end
          end

          private

          def stub_build
            ::Ci::Build.new(build_attributes)
          end

          def build_attributes
            attributes.merge(pipeline_attributes)
          end
        end
      end
    end
  end
end
