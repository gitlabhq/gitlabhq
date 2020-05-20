# frozen_string_literal: true

module Banzai
  module Pipeline
    # Resolve a pipeline by name
    #
    # name - nil, Class or Symbol. The name to be resolved.
    #
    # Examples:
    #     Pipeline[nil] # => Banzai::Pipeline::FullPipeline
    #     Pipeline[:label] # => Banzai::Pipeline::LabelPipeline
    #     Pipeline[StatusPage::Pipeline::PostProcessPipeline] # => StatusPage::Pipeline::PostProcessPipeline
    #
    #     Pipeline['label'] # => raises ArgumentError - unsupport type
    #     Pipeline[Project] # => raises ArgumentError - not a subclass of BasePipeline
    #
    # Returns a pipeline class which is a subclass of Banzai::Pipeline::BasePipeline.
    def self.[](name)
      name ||= FullPipeline

      pipeline = case name
                 when Class
                   name
                 when Symbol
                   const_get("#{name.to_s.camelize}Pipeline", false)
                 end

      return pipeline if pipeline && pipeline < BasePipeline

      raise ArgumentError,
        "unsupported pipeline name #{name.inspect} (#{name.class})"
    end
  end
end
