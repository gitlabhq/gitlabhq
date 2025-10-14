# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        ##
        # Performs matrix variable interpolation in needs:parallel:matrix configurations.
        # This interpolator specifically handles the `$[[ matrix.VARIABLE_NAME ]]` syntax
        # to enable dynamic job dependencies based on matrix values.
        #
        class MatrixInterpolator
          MATRIX_EXPRESSION_REGEXP = Gitlab::UntrustedRegexp.new('(\$\[\[\s*matrix\.([a-zA-Z0-9_-]+)\s*\]\])')

          attr_reader :errors

          def initialize(matrix_variables)
            @matrix_variables = matrix_variables || {}
            @errors = []
          end

          def interpolate(needs_config)
            interpolate_value(needs_config)
          end

          private

          attr_reader :matrix_variables

          def interpolate_value(needs_config)
            case needs_config
            when String
              interpolate_string(needs_config)
            when Hash
              needs_config.transform_values { |config| interpolate_value(config) }
            when Array
              needs_config.map { |config| interpolate_value(config) }
            else
              needs_config
            end
          end

          def interpolate_string(needs_config)
            matches = MATRIX_EXPRESSION_REGEXP.scan(needs_config)

            return needs_config if matches.empty?

            matches.reduce(needs_config) do |result, match|
              full_match = match[0] # The full $[[ matrix.VAR ]] expression
              var_name = match[1]   # Just the variable name

              unless matrix_variables.key?(var_name)
                @errors << "'#{var_name}' does not exist in matrix configuration"

                next result
              end

              result.gsub(full_match, matrix_variables[var_name].to_s)
            end
          end
        end
      end
    end
  end
end
