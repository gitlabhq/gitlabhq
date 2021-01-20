# frozen_string_literal: true

module Types
  class BaseEnum < GraphQL::Schema::Enum
    extend GitlabStyleDeprecations

    class << self
      # Registers enum definition by the given DeclarativeEnum module
      #
      # @param enum_mod [Module] The enum module to be used
      # @param use_name [Boolean] Does not override the name if set `false`
      # @param use_description [Boolean] Does not override the description if set `false`
      #
      # Example:
      #
      #   class MyEnum < BaseEnum
      #     declarative_enum MyDeclarativeEnum
      #   end
      #
      def declarative_enum(enum_mod, use_name: true, use_description: true)
        graphql_name(enum_mod.name) if use_name
        description(enum_mod.description) if use_description

        enum_mod.definition.each { |key, content| value(key.to_s.upcase, content) }
      end

      def value(*args, **kwargs, &block)
        enum[args[0].downcase] = kwargs[:value] || args[0]
        kwargs = gitlab_deprecation(kwargs)

        super(*args, **kwargs, &block)
      end

      # Returns an indifferent access hash with the key being the downcased name of the attribute
      # and the value being the Ruby value (either the explicit `value` passed or the same as the value attr).
      def enum
        @enum_values ||= {}.with_indifferent_access
      end
    end
  end
end
