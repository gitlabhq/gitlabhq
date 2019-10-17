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
          if config.key?(:stages)
            process(:stages)
          elsif config.key?(:types)
            process(:types)
          else
            config
          end
        end

        private

        attr_reader :config

        delegate :wrap_stages, to: :class

        def process(keyword)
          stages = extract_stages(keyword)
          return config if stages.empty?

          stages = wrap_stages(stages)
          config[keyword] = stages
          config
        end

        def extract_stages(keyword)
          stages = config[keyword]
          return [] unless stages.is_a?(Array)

          stages
        end
      end
    end
  end
end
