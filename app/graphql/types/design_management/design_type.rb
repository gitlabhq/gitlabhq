# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignType < BaseObject
      graphql_name 'Design'
      description 'A single design'

      authorize :read_design

      alias_method :design, :object

      implements(Types::Notes::NoteableType)
      implements(Types::DesignManagement::DesignFields)

      field :versions,
            Types::DesignManagement::VersionType.connection_type,
            resolver: Resolvers::DesignManagement::VersionsResolver,
            description: "All versions related to this design ordered newest first",
            extras: [:parent]

      # Returns a `DesignManagement::Version` for this query based on the
      # `atVersion` argument passed to a parent node if present, or otherwise
      # the most recent `Version` for the issue.
      def cached_stateful_version(parent_node)
        version_gid = Gitlab::Graphql::FindArgumentInParent.find(parent_node, :at_version)

        # Caching is scoped to an `issue_id` to allow us to cache the
        # most recent `Version` for an issue
        Gitlab::SafeRequestStore.fetch([request_cache_base_key, 'stateful_version', object.issue_id, version_gid]) do
          if version_gid
            GitlabSchema.object_from_id(version_gid)&.sync
          else
            object.issue.design_versions.most_recent
          end
        end
      end

      def request_cache_base_key
        self.class.name
      end
    end
  end
end
