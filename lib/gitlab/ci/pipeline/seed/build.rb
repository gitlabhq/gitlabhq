module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build < Seed::Base
          attr_reader :pipeline, :attributes

          delegate :dig, to: :attributes

          def initialize(pipeline, attributes)
            @pipeline = pipeline
            @attributes = attributes
          end

          # TODO find a different solution
          #
          def user=(current_user)
            @attributes.merge!(user: current_user)
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
