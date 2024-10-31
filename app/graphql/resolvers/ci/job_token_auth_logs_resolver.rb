# frozen_string_literal: true

module Resolvers
  module Ci
    class JobTokenAuthLogsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      authorize :admin_project
      type ::Types::Ci::JobTokenAuthLogType, null: true

      extras [:lookahead]

      def resolve_with_lookahead(**_args)
        authorize!(object)

        apply_lookahead(::Ci::JobToken::Authorization.for_project(object))
      end

      private

      def preloads
        {
          origin_project: [:origin_project]
        }
      end
    end
  end
end
