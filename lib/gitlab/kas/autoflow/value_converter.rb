# frozen_string_literal: true

module Gitlab
  module Kas
    module Autoflow
      # Converts plain Ruby values into AutoFlow protobuf Values, so callers of
      # Gitlab::Kas::Client#start_workflow pass ordinary Ruby and never construct
      # the gRPC types directly. A String becomes a string_value, a Hash a
      # dict_value, an Array a list_value, and so on.
      module ValueConverter
        module_function

        # @param named [Hash{String => Object}] name => Ruby value
        # @return [Array<Gitlab::Agent::Autoflow::NamedValue>]
        def named_values(named)
          named.map do |name, value|
            ::Gitlab::Agent::Autoflow::NamedValue.new(name: name.to_s, value: to_value(value))
          end
        end

        # @param values [Array<Object>]
        # @return [Array<Gitlab::Agent::Autoflow::Value>]
        def values(values)
          values.map { |value| to_value(value) }
        end

        # @return [Gitlab::Agent::Autoflow::Value]
        def to_value(object)
          case object
          when ::Gitlab::Agent::Autoflow::Value
            object
          when ::String
            value(string_value: object)
          when ::Integer
            value(integer_value: object)
          when ::Float
            value(float_value: object)
          when true, false
            value(bool_value: object)
          when nil
            value(none_value: ::Gitlab::Agent::Autoflow::NoneValue::NONE_VALUE)
          when ::Array
            value(list_value: ::Gitlab::Agent::Autoflow::ListValue.new(values: values(object)))
          when ::Hash
            key_values = object.map do |key, val|
              ::Gitlab::Agent::Autoflow::KeyValue.new(key: to_value(key.to_s), val: to_value(val))
            end
            value(dict_value: ::Gitlab::Agent::Autoflow::DictValue.new(key_values: key_values))
          else
            raise ArgumentError, "unsupported AutoFlow value type: #{object.class}"
          end
        end

        def value(**kwargs)
          ::Gitlab::Agent::Autoflow::Value.new(**kwargs)
        end
      end
    end
  end
end
