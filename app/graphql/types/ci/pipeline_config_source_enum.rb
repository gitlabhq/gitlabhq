# frozen_string_literal: true

module Types
  module Ci
    class PipelineConfigSourceEnum < BaseEnum
      ::Enums::Ci::Pipeline.config_sources.keys.each do |state_symbol|
        description = state_symbol == :auto_devops_source ? "Auto DevOps source." : "#{state_symbol.to_s.titleize.capitalize}." # This is needed to avoid failure in doc lint
        value state_symbol.to_s.upcase, value: state_symbol.to_s, description: description
      end
    end
  end
end
