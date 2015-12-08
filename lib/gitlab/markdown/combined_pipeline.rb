require 'gitlab/markdown'

module Gitlab
  module Markdown
    module CombinedPipeline
      def self.new(*pipelines)
        Class.new(Pipeline) do
          const_set :PIPELINES, pipelines

          def self.pipelines
            self::PIPELINES
          end

          def self.filters
            pipelines.flat_map(&:filters)
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
