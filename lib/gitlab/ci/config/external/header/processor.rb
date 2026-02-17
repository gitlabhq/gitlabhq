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

            def validate!
              all_input_keys = []

              @external_files.each do |file|
                file_inputs = file.to_hash[:inputs]
                all_input_keys.concat(file_inputs.keys) if file_inputs.present?
              end

              inline_inputs = @values[:inputs]
              all_input_keys.concat(inline_inputs.keys) if inline_inputs.present?

              duplicate_keys = all_input_keys.tally.select { |_, count| count > 1 }.keys

              return if duplicate_keys.empty?

              raise DuplicateInputError,
                "Duplicate input keys found: #{duplicate_keys.join(', ')}. " \
                  "Input keys must be unique across all included files and inline specifications."
            end
          end
        end
      end
    end
  end
end
