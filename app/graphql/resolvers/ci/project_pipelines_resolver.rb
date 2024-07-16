# frozen_string_literal: true

# rubocop: disable Graphql/ResolverType -- The GraphQL type here gets defined in
# https://gitlab.com/gitlab-org/gitlab/blob/master/app/graphql/resolvers/concerns/resolves_pipelines.rb#L7

module Resolvers
  module Ci
    class ProjectPipelinesResolver < BaseResolver
      include LooksAhead
      include ResolvesPipelines

      alias_method :project, :object

      def resolve_with_lookahead(**args)
        apply_lookahead(resolve_pipelines(project, args))
      end

      private

      def preloads
        {
          jobs: { statuses_order_id_desc: [:needs] },
          upstream: [:triggered_by_pipeline],
          downstream: [:triggered_pipelines]
        }
      end
    end
  end
end
# rubocop: enable Graphql/ResolverType

Resolvers::Ci::ProjectPipelinesResolver.prepend_mod
