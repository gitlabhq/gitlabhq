# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Converts locations to canonical form (local:/remote:) if String
          class Normalizer < Base
            def initialize(context)
              super

              @variables_expander = VariablesExpander.new(context)
            end

            private

            attr_reader :variables_expander

            def process_without_instrumentation(locations)
              locations.map do |location|
                if location.is_a?(String)
                  # We need to expand before normalizing because the information of
                  # whether if it's a remote or local path may be hidden inside the variable.
                  location = variables_expander.expand(location)

                  normalize_location_string(location)
                elsif location.is_a?(Hash)
                  location.deep_symbolize_keys
                else
                  raise Mapper::InvalidTypeError, 'Each include must be a hash or a string'
                end
              end
            end

            def normalize_location_string(location)
              if ::Gitlab::UrlSanitizer.valid?(location)
                { remote: location }
              else
                { local: location }
              end
            end
          end
        end
      end
    end
  end
end
