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

            @only = attributes.delete(:only)
            @except = attributes.delete(:except)
          end

          # TODO find a different solution
          #
          def user=(current_user)
            @attributes.merge!(user: current_user)
          end

          def included?
            strong_memoize(:inclusion) do
              only_specs = Gitlab::Ci::Build::Policy.fabricate(@only)
              except_specs = Gitlab::Ci::Build::Policy.fabricate(@except)

              only_specs.all? { |spec| spec.satisfied_by?(@pipeline) } &&
                except_specs.none? { |spec| spec.satisfied_by?(@pipeline) }
            end
          end

          def attributes
            @attributes.merge(
              pipeline: @pipeline,
              project: @pipeline.project,
              ref: @pipeline.ref,
              tag: @pipeline.tag,
              trigger_request: @pipeline.legacy_trigger,
              protected: @pipeline.protected_ref?
            )
          end

          def to_resource
            ::Ci::Build.new(attributes)
          end
        end
      end
    end
  end
end
