# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Stages
        EDGE_PRE = '.pre'
        EDGE_POST = '.post'
        EDGES = [EDGE_PRE, EDGE_POST].freeze

        def self.wrap_with_edge_stages(stages)
          stages = stages.to_a - EDGES
          stages.unshift EDGE_PRE
          stages.push EDGE_POST

          stages
        end

        def initialize(config)
          @config = config.to_h.deep_dup
          @stages = extract_stages
        end

        def inject_edge_stages!
          return config if stages.empty?

          config[:stages] = wrap_with_edge_stages(stages)
          config
        end

        private

        attr_reader :config, :stages

        delegate :wrap_with_edge_stages, to: :class

        def extract_stages
          stages = config[:stages]
          return [] unless stages.is_a?(Array)

          stages
        end
      end
    end
  end
end

Gitlab::Ci::Config::Stages.prepend_mod
