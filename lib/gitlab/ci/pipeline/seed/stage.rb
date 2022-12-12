# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Stage < Seed::Base
          include Gitlab::Utils::StrongMemoize

          delegate :size, to: :seeds
          delegate :dig, to: :seeds

          attr_reader :attributes

          def initialize(context, stage_attributes, previous_stages)
            pipeline = context.pipeline
            @attributes = {
              name: stage_attributes.fetch(:name),
              position: stage_attributes.fetch(:index),
              pipeline: pipeline,
              project: pipeline.project,
              partition_id: pipeline.partition_id
            }

            @stage = ::Ci::Stage.new(@attributes)

            @builds = stage_attributes.fetch(:builds).map do |build_attributes|
              Seed::Build.new(context, build_attributes, previous_stages + [self], @stage)
            end
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
            @stage.statuses = seeds.map(&:to_resource)
            @stage
          end
          strong_memoize_attr :to_resource
        end
      end
    end
  end
end
