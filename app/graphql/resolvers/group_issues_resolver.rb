# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType (inherited from Issues::BaseParentResolver)
module Resolvers
  class GroupIssuesResolver < Issues::BaseParentResolver
    def self.issuable_collection_name
      'issues'
    end

    include GroupIssuableResolver

    before_connection_authorization do |nodes, _|
      projects = nodes.map(&:project)
      ActiveRecord::Associations::Preloader.new(records: projects, associations: :namespace).call
    end

    def ready?(**args)
      if args.dig(:not, :release_tag).present?
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'releaseTag filter is not allowed when parent is a group.'
      end

      super
    end
  end
end
# rubocop:enable Graphql/ResolverType
