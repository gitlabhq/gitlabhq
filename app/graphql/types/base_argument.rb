# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
    include Gitlab::Graphql::Deprecations

    attr_reader :doc_reference

    def initialize(*args, **kwargs, &block)
      @doc_reference = kwargs.delete(:see)

      super(*args, **kwargs, &block)
    end
  end
end
