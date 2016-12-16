module Gitlab
  module Serialize
    module Ci
      # This serializer could make sure our YAML variables' keys and values
      # are always strings. This is more for legacy build data because
      # from now on we convert them into strings before saving to database.
      module Variables
        extend self

        def load(string)
          return unless string

          object = YAML.safe_load(string, [Symbol])

          object.map(&Variables.method(:convert_key_value_to_string))
        end

        def dump(object)
          YAML.dump(object)
        end

        private

        def convert_key_value_to_string(variable)
          variable[:key] = variable[:key].to_s
          variable[:value] = variable[:value].to_s
          variable
        end
      end
    end
  end
end
