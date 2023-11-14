# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      class VersionsResolver < ::Resolvers::ReleasesResolver
        type Types::ReleaseType.connection_type, null: true

        # This allows a maximum of 1 call to the field that uses this resolver. If the
        # field is evaluated on more than one node, it causes performance degradation.
        extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

        private

        def get_project
          object.respond_to?(:project) ? object.project : object
        end

        # Override the aliased method in ReleasesResolver
        alias_method :project, :get_project
      end
    end
  end
end
