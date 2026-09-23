# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable GraphQL/GraphqlName -- Not a type
    # rubocop: disable Graphql/AuthorizeTypes -- Not a type
    class JobInterfaceBaseField < ::Types::BaseField
      # `trace` can expose debug-mode CI/CD variable values, so it needs the
      # stricter :read_build_trace ability rather than the interface default
      # :read_build (matches the REST endpoint and Ci::BuildPolicy). Applying it
      # here covers every type that implements JobInterface.
      READ_BUILD_TRACE_FIELDS = %i[trace].freeze

      def initialize(**kwargs, &block)
        kwargs[:authorize] = READ_BUILD_TRACE_FIELDS.include?(kwargs[:name]) ? :read_build_trace : :read_build

        super
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
    # rubocop: enable GraphQL/GraphqlName
  end
end
