module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build < Seed::Base
          include Gitlab::Utils::StrongMemoize

          delegate :dig, to: :@attributes

          def initialize(pipeline, attributes)
            @pipeline = pipeline
            @attributes = attributes

            @only = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:only))
            @except = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:except))
          end

          def included?
            strong_memoize(:inclusion) do
              @only.all? { |spec| spec.satisfied_by?(@pipeline, self) } &&
                @except.none? { |spec| spec.satisfied_by?(@pipeline, self) }
            end
          end

          def parallel?
            !!@attributes.dig(:options, :parallel)
          end

          def parallelize_build
            total = @attributes[:options][:parallel]
            Array.new(total) { ::Ci::Build.new(attributes) }
              .each_with_index { |build, idx| build.name = "#{build.name} #{idx + 1}/#{total}" }
          end

          def attributes
            @attributes.merge(
              pipeline: @pipeline,
              project: @pipeline.project,
              user: @pipeline.user,
              ref: @pipeline.ref,
              tag: @pipeline.tag,
              trigger_request: @pipeline.legacy_trigger,
              protected: @pipeline.protected_ref?
            )
          end

          def to_resource
            strong_memoize(:resource) do
              parallel? ? parallelize_build : ::Ci::Build.new(attributes)
            end
          end
        end
      end
    end
  end
end
