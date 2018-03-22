module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Stage < Seed::Base
          include Gitlab::Utils::StrongMemoize

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

          def seeds
            strong_memoize(:seeds_included) do
              @seeds.select(&:included?)
            end
          end

          def included?
            seeds.any?
          end

          def to_resource
            strong_memoize(:stage) do
              ::Ci::Stage.new(attributes).tap do |stage|
                seeds.each { |seed| stage.builds << seed.to_resource }
              end
            end
          end
        end
      end
    end
  end
end
