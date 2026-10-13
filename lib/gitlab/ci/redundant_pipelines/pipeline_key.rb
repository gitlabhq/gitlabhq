# frozen_string_literal: true

module Gitlab
  module Ci
    module RedundantPipelines
      # A pipeline's composite primary key, so collaborators can pass a pipeline
      # reference around, and later load it from its partition, without loading the
      # record itself.
      #
      #   PipelineKey.of(pipeline).to_s # => "42:100"
      class PipelineKey
        SEPARATOR = ':'

        attr_reader :pipeline_id, :partition_id

        def self.of(pipeline)
          new(pipeline.id, pipeline.partition_id)
        end

        def self.parse(value)
          new(*value.to_s.split(SEPARATOR, 2).map(&:to_i))
        end

        def initialize(pipeline_id, partition_id)
          @pipeline_id = pipeline_id
          @partition_id = partition_id
        end

        def to_s
          [pipeline_id, partition_id].join(SEPARATOR)
        end

        def ==(other)
          other.class == self.class && other.to_s == to_s
        end
        alias_method :eql?, :==

        def hash
          to_s.hash
        end
      end
    end
  end
end
