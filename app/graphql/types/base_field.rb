# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    prepend Gitlab::Graphql::Authorize

    DEFAULT_COMPLEXITY = 1

    def initialize(*args, **kwargs, &block)
      # complexity is already defaulted to 1, but let's make it explicit
      kwargs[:complexity] ||= DEFAULT_COMPLEXITY

      super(*args, **kwargs, &block)
    end
  end
end
