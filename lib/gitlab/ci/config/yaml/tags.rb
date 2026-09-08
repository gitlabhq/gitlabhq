# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        module Tags
          TagError = Class.new(StandardError)

          # The first unresolved YAML tag (for example `!reference`) the value
          # is or contains, or `nil`. Tags are only resolved by
          # `Tags::Resolver`, which runs after input interpolation.
          def self.find_unresolved_tag(value)
            case value
            when Base
              value
            when Array
              value.lazy.filter_map { |item| find_unresolved_tag(item) }.first
            when Hash
              # Flattened so that tags used as keys are checked too.
              find_unresolved_tag(value.flatten(1))
            end
          end
        end
      end
    end
  end
end
