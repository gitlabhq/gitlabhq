
module Gitlab
  module Serialize
    # This serializer could make sure our YAML variables' keys and values
    # are always strings. This is more for legacy build data because
    # from now on we convert them into strings before saving to database.
    module YamlVariables
      extend self

      def load(string)
        return unless string

        object = YAML.load(string)

        # We don't need to verify the object once we're using SafeYAML
        if YamlVariables.verify_object(object)
          YamlVariables.convert_object(object)
        else
          []
        end
      end

      def dump(object)
        YAML.dump(object)
      end

      def verify_object(object)
        YamlVariables.verify_type(object, Array) &&
          object.all? { |obj| YamlVariables.verify_type(obj, Hash) }
      end

      # We use three ways to check if the class is exactly the one we want,
      # rather than some subclass or duck typing class.
      def verify_type(object, klass)
        object.kind_of?(klass) &&
          object.class == klass &&
          klass === object
      end

      def convert_object(object)
        object.map(&YamlVariables.method(:convert_key_value_to_string))
      end

      def convert_key_value_to_string(variable)
        variable[:key] = variable[:key].to_s
        variable[:value] = variable[:value].to_s
        variable
      end
    end
  end
end
