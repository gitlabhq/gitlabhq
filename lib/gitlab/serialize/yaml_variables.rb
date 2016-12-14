
module Gitlab
  module Serialize
    # This serializer could make sure our YAML variables' keys and values
    # are always strings. This is more for legacy build data because
    # from now on we convert them into strings before saving to database.
    module YamlVariables
      extend self

      def load(string)
        return unless string

        YAML.load(string).
          map(&YamlVariables.method(:convert_key_value_to_string))
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
