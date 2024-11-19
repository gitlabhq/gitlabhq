# frozen_string_literal: true

module Resolvers
  module Ci
    class JobTokenScopeAllowlistResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :admin_project

      type ::Types::Ci::JobTokenScope::AllowlistType, null: true

      alias_method :source_project, :object

      def resolve(**_args)
        authorize!(source_project)

        groups_allowlist = ::Ci::JobToken::GroupScopeLink.with_source(source_project)
        projects_allowlist = ::Ci::JobToken::ProjectScopeLink.with_source(source_project)

        {
          groups_allowlist: groups_allowlist,
          projects_allowlist: projects_allowlist
        }
      end
    end
  end
end
