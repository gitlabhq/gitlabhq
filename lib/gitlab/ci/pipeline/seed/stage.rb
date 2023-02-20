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
              Seed::Build.new(context, attributes, previous_stages + [self])
            end
          end

          def attributes
            { name: @attributes.fetch(:name),
              position: @attributes.fetch(:index),
              pipeline: @pipeline,
              project: @pipeline.project,
              partition_id: @pipeline.partition_id }
          end

          def seeds
            @builds.select(&:included?)
          end
          strong_memoize_attr :seeds

          def errors
            @builds.flat_map(&:errors).compact
          end
          strong_memoize_attr :errors

          def seeds_names
            seeds.map(&:name).to_set
          end
          strong_memoize_attr :seeds_names

          def included?
            seeds.any?
          end

          def to_resource
            ::Ci::Stage.new(attributes).tap do |stage|
              stage.statuses = seeds.map(&:to_resource)
            end
          end
          strong_memoize_attr :to_resource
        end
      end
    end
  end
end
