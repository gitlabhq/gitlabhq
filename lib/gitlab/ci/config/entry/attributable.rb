module Gitlab
  module Ci
    class Config
      module Entry
        module Attributable
          extend ActiveSupport::Concern

          class_methods do
            def attributes(*attributes)
              attributes.flatten.each do |attribute|
                raise ArgumentError if method_defined?(attribute)

                define_method(attribute) do
                  return unless config.is_a?(Hash)

                  config[attribute]
                end
              end
            end
          end
        end
      end
    end
  end
end
