# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignType < BaseObject
      graphql_name 'Design'
      description 'A single design'

      authorize :read_design

      alias_method :design, :object

      implements Types::Notes::NoteableInterface
      implements Types::DesignManagement::DesignFields
      implements Types::CurrentUserTodos
      implements Types::TodoableInterface

      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description of the design.'

      field :web_url,
        GraphQL::Types::String,
        null: false,
        description: 'URL of the design.'

      field :versions,
        Types::DesignManagement::VersionType.connection_type,
        resolver: Resolvers::DesignManagement::VersionsResolver,
        description: "All versions related to this design ordered newest first."

      field :imported,
        GraphQL::Types::Boolean,
        null: false,
        method: :imported?,
        description: 'Indicates whether the design was imported.'

      field :imported_from,
        Types::Import::ImportSourceEnum,
        null: false,
        description: 'Import source of the design.'

      markdown_field :description_html, null: true

      # Returns a `DesignManagement::Version` for this query based on the
      # `atVersion` argument passed to a parent node if present, or otherwise
      # the most recent `Version` for the issue.
      def cached_stateful_version(parent_node)
        version_gid = context[:at_version_argument] # See: DesignsResolver

        # Caching is scoped to an `issue_id` to allow us to cache the
        # most recent `Version` for an issue
        Gitlab::SafeRequestStore.fetch([request_cache_base_key, 'stateful_version', object.issue_id, version_gid]) do
          if version_gid
            GitlabSchema.object_from_id(version_gid, expected_type: ::DesignManagement::Version)&.sync
          else
            object.issue.design_versions.most_recent
          end
        end
      end

      def request_cache_base_key
        self.class.name
      end

      def web_url
        Gitlab::UrlBuilder.build(object)
      end

      def name
        object.filename
      end
    end
  end
end
