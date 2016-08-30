module Gitlab
  module Ci
    class Config
      module Node
        module Attributable
          extend ActiveSupport::Concern

          class_methods do
            def attributes(*attributes)
              attributes.flatten.each do |attribute|
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
