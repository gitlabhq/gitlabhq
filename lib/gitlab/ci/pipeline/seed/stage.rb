module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Stage < Seed::Base
          attr_reader :pipeline

          delegate :project, to: :pipeline
          delegate :size, to: :@builds

          def initialize(pipeline, name, builds)
            @pipeline = pipeline
            @name = name

            @builds = builds.map do |attributes|
              Seed::Build.new(pipeline, attributes)
            end
          end

          def user=(current_user)
            @builds.each { |seed| seed.user = current_user }
          end

          def attributes
            { name: @name, project: project }
          end

          # TODO decouple from Seed::Build
          def builds_attributes
            @builds.map(&:attributes)
          end

          def create!
            pipeline.stages.build(attributes).tap do |stage|
              builds_attributes.each do |build_attributes|
                stage.builds.build(build_attributes).tap do |build|
                  build.pipeline = pipeline
                end
              end

              stage.save!

              stage.builds.each do |build|
                yield build if block_given?
              end
            end
          end

          private

          def protected_ref?
          end
        end
      end
    end
  end
end
