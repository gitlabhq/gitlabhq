# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
    include Gitlab::Graphql::Deprecations

    attr_reader :doc_reference

    def initialize(*args, **kwargs, &block)
      init_gitlab_deprecation(kwargs)
      @doc_reference = kwargs.delete(:see)

      # our custom addition `nullable` which allows us to declare
      # an argument that must be provided, even if its value is null.
      # When `required: true` then required arguments must not be null.
      @gl_required = !!kwargs[:required]
      @gl_nullable = kwargs[:required] == :nullable

      # Only valid if an argument is also required.
      if @gl_nullable
        # Since the framework asserts that "required" means "cannot be null"
        # we have to switch off "required" but still do the check in `ready?` behind the scenes
        kwargs[:required] = false
      end

      super(*args, **kwargs, &block)
    end

    def accepts?(value)
      # if the argument is declared as required, it must be included
      return false if @gl_required && value == :not_given
      # if the argument is declared as required, the value can only be null IF it is also nullable.
      return false if @gl_required && value.nil? && !@gl_nullable

      true
    end
  end
end
