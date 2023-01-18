# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      module Attributable
        extend ActiveSupport::Concern

        class_methods do
          def attributes(*attributes, prefix: nil)
            attributes.flatten.each do |attribute|
              attribute_method = prefix ? "#{prefix}_#{attribute}" : attribute

              if method_defined?(attribute_method)
                raise ArgumentError, "Method '#{attribute_method}' already defined in '#{name}'"
              end

              define_method(attribute_method) do
                return unless config.is_a?(Hash)

                config[attribute]
              end

              define_method("has_#{attribute_method}?") do
                config.is_a?(Hash) && config.key?(attribute)
              end

              define_method("has_#{attribute_method}_value?") do
                config.is_a?(Hash) && config.key?(attribute) && !config[attribute].nil?
              end
            end
          end
        end
      end
    end
  end
end
