# frozen_string_literal: true

module Resolvers
  class NilResolver < BaseResolver # rubocop:disable Gitlab/BoundedContexts -- Part of base GraphQL feature
    # An object type, not a scalar: analyzers walk the subselections of a
    # missing tagged field and need fallback fields for them.
    type ::Gitlab::Graphql::VersionFilter::NilObjectType, null: true
    description 'Returns nil. Used to resolve the value of missing fields with the @gl_introduced directive.'

    def resolve
      nil
    end
  end
end
