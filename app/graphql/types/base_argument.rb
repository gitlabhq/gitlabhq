# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
    include Gitlab::Graphql::Deprecations

    # Default maximum size for array arguments
    # This provides automatic validation for array arguments during the transition period
    # while we add explicit validates: { length: { maximum: ... } } to all array arguments.
    #
    # Recommended usage (explicit validation):
    #   argument :items, [GraphQL::Types::String],
    #     validates: { length: { maximum: MAX_ARRAY_SIZE } },
    #     description: "Items (maximum is #{MAX_ARRAY_SIZE})."
    #
    # Fallback (automatic validation):
    #   argument :items, [GraphQL::Types::String]
    #   # Automatically limited to MAX_ARRAY_SIZE items
    MAX_ARRAY_SIZE = 100

    attr_reader :doc_reference

    def initialize(*args, **kwargs, &block)
      @doc_reference = kwargs.delete(:see)

      # GraphQL-Ruby can pass type in two ways:
      # 1. As second positional arg: argument(:name, Type, ...)
      # 2. As keyword arg: argument(:name, type: Type, ...)
      argument_type = kwargs[:type] || args[1]
      validates_option = kwargs[:validates]

      # Add automatic array size validation if no explicit length validation exists
      add_automatic_array_validation!(kwargs) if add_validation?(argument_type, validates_option)

      super(*args, **kwargs, &block)
    end

    private

    def add_validation?(type, validates_option)
      # Only add automatic validation if:
      # 1. Type is an array
      # 2. No explicit validates: { length: { maximum: ... } } exists
      return false unless array_type?(type)
      return false if has_length_validation_in_options?(validates_option)

      true
    end

    def array_type?(type)
      # Check if the type is an array type
      # GraphQL-Ruby represents array types as Array instances
      type.is_a?(Array) || (type.respond_to?(:list?) && type.list?)
    end

    def has_length_validation_in_options?(validates_option)
      return false unless validates_option.is_a?(Hash)

      validates_option.dig(:length, :maximum).present?
    end

    def add_automatic_array_validation!(kwargs)
      # Wrap any existing prepare proc with our validation
      existing_prepare = kwargs[:prepare]

      kwargs[:prepare] = ->(value, ctx) {
        # Call existing prepare if it exists
        prepared_value = existing_prepare ? existing_prepare.call(value, ctx) : value

        # Validate array size
        if prepared_value.is_a?(Array) && prepared_value.size > MAX_ARRAY_SIZE
          log_argument_size(ctx.query.operation_name, prepared_value.size)
        end

        prepared_value
      }
    end

    def log_argument_size(operation_name, value_size)
      argument_name = "#{owner.name}##{name}"

      ::Gitlab::GraphqlLogger.info(
        Gitlab::ApplicationContext.current.merge(
          {
            message: "Array argument over the size limit",
            operation_name: operation_name,
            array_argument_name: argument_name,
            value_size: value_size
          }
        )
      )
    end
  end
end
