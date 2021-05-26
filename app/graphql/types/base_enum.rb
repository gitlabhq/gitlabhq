# frozen_string_literal: true

module Types
  class BaseEnum < GraphQL::Schema::Enum
    class CustomValue < GraphQL::Schema::EnumValue
      include ::GitlabStyleDeprecations

      attr_reader :deprecation

      def initialize(name, desc = nil, **kwargs)
        @deprecation = gitlab_deprecation(kwargs)

        super(name, desc, **kwargs)
      end
    end

    enum_value_class(CustomValue)

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
      # Disabling descriptions rubocop for a false positive here
      # rubocop: disable Graphql/Descriptions
      #
      def declarative_enum(enum_mod, use_name: true, use_description: true)
        graphql_name(enum_mod.name) if use_name
        description(enum_mod.description) if use_description

        enum_mod.definition.each do |key, content|
          value(key.to_s.upcase, **content)
        end
      end
      # rubocop: enable Graphql/Descriptions

      # Helper to define an enum member for each element of a Rails AR enum
      def from_rails_enum(enum, description:)
        enum.each_key do |name|
          value name.to_s.upcase,
                value: name,
                description: format(description, name: name)
        end
      end

      def value(*args, **kwargs, &block)
        enum[args[0].downcase] = kwargs[:value] || args[0]

        super(*args, **kwargs, &block)
      end

      # Returns an indifferent access hash with the key being the downcased name of the attribute
      # and the value being the Ruby value (either the explicit `value` passed or the same as the value attr).
      def enum
        @enum_values ||= {}.with_indifferent_access
      end

      def authorization
        @authorization ||= ::Gitlab::Graphql::Authorize::ObjectAuthorization.new(authorize)
      end

      def authorize(*abilities)
        @abilities = abilities
      end

      def authorized?(object, context)
        authorization.ok?(object, context[:current_user])
      end
    end
  end
end
