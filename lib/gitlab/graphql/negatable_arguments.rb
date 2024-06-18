# frozen_string_literal: true

module Gitlab
  module Graphql
    module NegatableArguments
      class TypeDefiner
        def initialize(resolver_class, type_definition)
          @resolver_class = resolver_class
          @type_definition = type_definition
        end

        def define!
          negated_params_type.instance_eval(&@type_definition)
        end

        def negated_params_type
          @negated_params_type ||= existing_type || build_type
        end

        private

        def existing_type
          ::Types.const_get(type_class_name, false) if ::Types.const_defined?(type_class_name)
        end

        def build_type
          klass = Class.new(::Types::BaseInputObject)
          ::Types.const_set(type_class_name, klass)
          klass
        end

        def type_class_name
          @type_class_name ||= begin
            base_name = @resolver_class.name.sub('Resolvers::', '')
            base_name + 'NegatedParamsType'
          end
        end
      end

      def negated(param_key: :not, &block)
        definer = ::Gitlab::Graphql::NegatableArguments::TypeDefiner.new(self, block)
        definer.define!

        argument param_key, definer.negated_params_type,
          required: false,
          description: <<~MD
                     List of negated arguments.
                     Warning: this argument is experimental and a subject to change in future.
          MD
      end
    end
  end
end
