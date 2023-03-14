# frozen_string_literal: true

module Gitlab
  module Serializer
    module Ci
      # This serializer could make sure our YAML variables' keys and values
      # are always strings. This is more for legacy build data because
      # from now on we convert them into strings before saving to database.
      module Variables
        extend self

        def load(string)
          return unless string

          object = YAML.safe_load(string, permitted_classes: [Symbol])

          object.map do |variable|
            variable.symbolize_keys.tap do |variable|
              variable[:key] = variable[:key].to_s
            end
          end
        end

        def dump(object)
          YAML.dump(object)
        end
      end
    end
  end
end
