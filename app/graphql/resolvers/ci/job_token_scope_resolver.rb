# frozen_string_literal: true

module Resolvers
  module Ci
    class JobTokenScopeResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :admin_project
      description 'Container for resources that can be accessed by a CI job token from the current project. Null if job token scope setting is disabled.'
      type ::Types::Ci::JobTokenScopeType, null: true

      def resolve
        authorize!(object)

        return unless object.ci_job_token_scope_enabled?

        ::Ci::JobToken::Scope.new(object)
      end
    end
  end
end
