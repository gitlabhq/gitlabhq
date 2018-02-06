module Gitlab
  module Ci
    class Config
      module Entry
        module Attributable
          extend ActiveSupport::Concern

          class_methods do
            def attributes(*attributes)
              attributes.flatten.each do |attribute|
                if method_defined?(attribute)
                  raise ArgumentError, 'Method already defined!'
                end

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
