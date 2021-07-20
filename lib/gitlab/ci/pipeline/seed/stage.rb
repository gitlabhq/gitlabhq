# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Stage < Seed::Base
          include Gitlab::Utils::StrongMemoize

          delegate :size, to: :seeds
          delegate :dig, to: :seeds

          def initialize(context, attributes, previous_stages)
            @context = context
            @pipeline = context.pipeline
            @attributes = attributes
            @previous_stages = previous_stages

            @builds = attributes.fetch(:builds).map do |attributes|
              Seed::Build.new(context, attributes, previous_stages, self)
            end
          end

          def attributes
            { name: @attributes.fetch(:name),
              position: @attributes.fetch(:index),
              pipeline: @pipeline,
              project: @pipeline.project }
          end

          def seeds
            strong_memoize(:seeds) do
              @builds.select(&:included?)
            end
          end

          def errors
            strong_memoize(:errors) do
              seeds.flat_map(&:errors).compact
            end
          end

          def seeds_names
            strong_memoize(:seeds_names) do
              seeds.map(&:name).to_set
            end
          end

          def included?
            seeds.any?
          end

          def to_resource
            strong_memoize(:stage) do
              ::Ci::Stage.new(attributes).tap do |stage|
                stage.statuses = seeds.map(&:to_resource)
              end
            end
          end
        end
      end
    end
  end
end
