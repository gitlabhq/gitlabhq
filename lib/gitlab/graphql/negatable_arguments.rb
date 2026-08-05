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
          namespace_path, _, name = type_class_name.rpartition('::')
          namespace_for(namespace_path).const_set(name, klass)
          klass
        end

        # Resolvers in nested modules, for example `Resolvers::Namespaces::BaseGroupsResolver`, get their
        # negated params type defined in the matching `Types` module, creating it when it does not exist yet.
        def namespace_for(path)
          return ::Types if path.empty?

          path.split('::').reduce(::Types) do |namespace, module_name|
            if namespace.const_defined?(module_name, false)
              namespace.const_get(module_name, false)
            else
              namespace.const_set(module_name, Module.new)
            end
          end
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
