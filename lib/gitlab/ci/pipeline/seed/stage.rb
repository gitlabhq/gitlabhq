module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Stage < Seed::Base
          delegate :size, to: :@seeds

          def initialize(pipeline, name, builds)
            @pipeline = pipeline
            @name = name

            @seeds = builds.map do |attributes|
              Seed::Build.new(@pipeline, attributes)
            end
          end

          def user=(current_user)
            @seeds.each { |seed| seed.user = current_user }
          end

          def attributes
            { name: @name,
              pipeline: @pipeline,
              project: @pipeline.project }
          end

          # TODO decouple
          #
          def builds_attributes
            @seeds.map(&:attributes)
          end

          def to_resource
            ::Ci::Stage.new(attributes).tap do |stage|
              @seeds.each do |seed|
                seed.to_resource.tap do |build|
                  stage.builds << build
                end
              end

              @pipeline.stages << stage
            end
          end
        end
      end
    end
  end
end
