# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
    include GitlabStyleDeprecations

    attr_reader :deprecation, :doc_reference

    def initialize(*args, **kwargs, &block)
      @deprecation = gitlab_deprecation(kwargs)
      @doc_reference = kwargs.delete(:see)

      super(*args, **kwargs, &block)
    end
  end
end
