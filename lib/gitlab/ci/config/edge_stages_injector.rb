# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class EdgeStagesInjector
        PRE_PIPELINE = '.pre'
        POST_PIPELINE = '.post'
        EDGES = [PRE_PIPELINE, POST_PIPELINE].freeze

        def self.wrap_stages(stages)
          stages = stages.to_a - EDGES
          stages.unshift PRE_PIPELINE
          stages.push POST_PIPELINE

          stages
        end

        def initialize(config)
          @config = config.to_h.deep_dup
        end

        def to_hash
          return config unless config.key?(:stages)

          inject_edges
        end

        private

        attr_reader :config

        delegate :wrap_stages, to: :class

        def inject_edges
          stages = extract_stages
          return config if stages.empty?

          stages = wrap_stages(stages)
          config[:stages] = stages
          config
        end

        def extract_stages
          stages = config[:stages]
          return [] unless stages.is_a?(Array)

          stages
        end
      end
    end
  end
end
