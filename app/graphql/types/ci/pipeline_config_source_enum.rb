# frozen_string_literal: true

module Types
  module Ci
    class PipelineConfigSourceEnum < BaseEnum
      ::Enums::Ci::Pipeline.config_sources.keys.each do |state_symbol|
        value state_symbol.to_s.upcase, value: state_symbol.to_s
      end
    end
  end
end
