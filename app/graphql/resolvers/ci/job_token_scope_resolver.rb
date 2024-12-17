# frozen_string_literal: true

module Resolvers
  module Ci
    # TODO: remove in 18.0, after https://gitlab.com/gitlab-org/govern/authorization/team-tasks/-/issues/87 is resolved
    class JobTokenScopeResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :admin_project
      description 'Container for resources that can be accessed by a CI job token from the current project.'
      type ::Types::Ci::JobTokenScopeType, null: true

      def resolve
        authorize!(object)

        ::Ci::JobToken::Scope.new(object)
      end
    end
  end
end
