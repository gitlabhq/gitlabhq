# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      module Attributable
        extend ActiveSupport::Concern

        class_methods do
          def attributes(*attributes)
            attributes.flatten.each do |attribute|
              if method_defined?(attribute)
                raise ArgumentError, "Method already defined: #{attribute}"
              end

              define_method(attribute) do
                return unless config.is_a?(Hash)

                config[attribute]
              end

              define_method("has_#{attribute}?") do
                config.is_a?(Hash) && config.key?(attribute)
              end
            end
          end
        end
      end
    end
  end
end
