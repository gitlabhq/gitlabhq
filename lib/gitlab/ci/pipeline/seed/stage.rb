module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Stage < Seed::Base
          attr_reader :pipeline, :seeds

          delegate :size, to: :seeds
          delegate :dig, to: :seeds

          def initialize(pipeline, attributes)
            @pipeline = pipeline
            @attributes = attributes

            @seeds = attributes.fetch(:builds).map do |attributes|
              Seed::Build.new(@pipeline, attributes)
            end
          end

          def user=(current_user)
            @seeds.each { |seed| seed.user = current_user }
          end

          def attributes
            { name: @attributes.fetch(:name),
              pipeline: @pipeline,
              project: @pipeline.project }
          end

          # TODO specs
          #
          def included?
            @seeds.any?(&:included?)
          end

          def to_resource
            @stage ||= ::Ci::Stage.new(attributes).tap do |stage|
              @seeds.each do |seed|
                next unless seed.included?

                stage.builds << seed.to_resource
              end
            end
          end
        end
      end
    end
  end
end
