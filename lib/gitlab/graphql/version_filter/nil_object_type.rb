# frozen_string_literal: true

module Gitlab
  module Graphql
    module VersionFilter
      # Return type of Resolvers::NilResolver. It always wraps nil, so its
      # subfields never resolve. It carries FutureFieldFallback so the
      # analyzers see fallback fields, not nil, under a missing tagged field.
      class NilObjectType < GraphQL::Schema::Object
        graphql_name 'NilObject'
        description 'Placeholder type for missing fields with the @gl_introduced directive. Always null.'

        # The type isn't registered in the schema; the introspection flag is
        # what lets the warden treat it as visible and reachable anyway.
        introspection true

        include FutureFieldFallback
      end
    end
  end
end
