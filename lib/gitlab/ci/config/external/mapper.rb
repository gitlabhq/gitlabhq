# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          include Gitlab::Utils::StrongMemoize

          Error = Class.new(StandardError)
          AmbigiousSpecificationError = Class.new(Error)
          TooManyIncludesError = Class.new(Error)
          TooMuchDataInPipelineTreeError = Class.new(Error)
          InvalidTypeError = Class.new(Error)

          def initialize(values, context)
            @locations = Array.wrap(values.fetch(:include, [])).compact
            @context = context
          end

          def process
            return [] if @locations.empty?

            context.logger.instrument(:config_mapper_process) do
              process_without_instrumentation
            end
          end

          private

          attr_reader :context

          delegate :expandset, :logger, to: :context

          def process_without_instrumentation
            locations = Normalizer.new(context).process(@locations)
            locations = Filter.new(context).process(locations)
            locations = LocationExpander.new(context).process(locations)
            locations = VariablesExpander.new(context).process(locations)

            files = Matcher.new(context).process(locations)
            Verifier.new(context).process(files)

            files
          end
        end
      end
    end
  end
end
