# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GitlabConfigMetric < GenericMetric
          value do
            method_name_array = config_hash_to_method_array(options[:config])

            method_name_array.inject(Gitlab.config, :public_send)
          end

          private

          def config_hash_to_method_array(object)
            object.each_with_object([]) do |(key, value), result|
              result.append(key)

              if value.is_a?(Hash)
                result.concat(config_hash_to_method_array(value))
              else
                result.append(value)
              end
            end
          end
        end
      end
    end
  end
end
