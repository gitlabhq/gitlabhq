# frozen_string_literal: true

module API
  module Helpers
    # GraphqlHelpers is used by the REST API when it is acting like a client
    # against the graphql API. Helper code for the graphql server implementation
    # should be in app/graphql/ or lib/gitlab/graphql/
    module GraphqlHelpers
      def run_graphql!(query:, context: {}, variables: nil, transform: nil)
        result = GitlabSchema.execute(query, variables: variables, context: context)

        if transform
          transform.call(result)
        else
          result
        end
      end
    end
  end
end
