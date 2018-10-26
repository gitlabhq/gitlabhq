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

          def parallelized?
            @attributes[:options].include?(:parallel)
          end

          def parallelize_build
            builds = []

            total = @attributes[:options][:parallel]

            total.times do |i|
              build = ::Ci::Build.new(attributes.merge(options: { variables: { CI_NODE_INDEX: i + 1, CI_NODE_TOTAL: total } }))
              build.name = build.name + "_#{i + 1}/#{total}"
              builds << build
            end

            builds
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
              if parallelized?
                parallelize_build
              else
                ::Ci::Build.new(attributes)
              end
            end
          end
        end
      end
    end
  end
end
