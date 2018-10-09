# frozen_string_literal: true

module Banzai
  module Pipeline
    module CombinedPipeline
      def self.new(*pipelines)
        Class.new(BasePipeline) do
          const_set :PIPELINES, pipelines

          def self.pipelines
            self::PIPELINES
          end

          def self.filters
            FilterArray.new(pipelines.flat_map(&:filters))
          end

          def self.transform_context(context)
            pipelines.reduce(context) do |context, pipeline|
              pipeline.transform_context(context)
            end
          end
        end
      end
    end
  end
end
