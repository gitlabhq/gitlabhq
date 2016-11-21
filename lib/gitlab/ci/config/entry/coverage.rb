module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a Regular Expression.
        #
        class Coverage < Node
          include Validatable

          ALLOWED_KEYS = %i[output_filter]

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :output_filter, regexp: true
          end

          def output_filter
            output_filter_value = @config[:output_filter].to_s

            if output_filter_value.start_with?('/') && output_filter_value.end_with?('/')
              output_filter_value[1...-1]
            else
              @config[:output_filter]
            end
          end

          def value
            @config.merge(output_filter: output_filter)
          end
        end
      end
    end
  end
end
