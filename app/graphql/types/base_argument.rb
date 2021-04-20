# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
    include GitlabStyleDeprecations

    attr_reader :deprecation

    def initialize(*args, **kwargs, &block)
      @deprecation = gitlab_deprecation(kwargs)

      super(*args, **kwargs, &block)
    end
  end
end
