# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module Header
          ##
          # Header include processor
          #
          # Processes header includes to merge input definitions.
          # Inherits from External::Processor and overrides only the Mapper instantiation.
          class Processor < ::Gitlab::Ci::Config::External::Processor
            private

            def mapper
              Header::Mapper.new(@values, @context)
            end
          end
        end
      end
    end
  end
end
