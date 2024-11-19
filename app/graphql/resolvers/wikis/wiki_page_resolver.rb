# frozen_string_literal: true

module Resolvers
  module Wikis
    class WikiPageResolver < BaseResolver
      description 'Retrieve a wiki page'

      type Types::Wikis::WikiPageType, null: true

      argument :slug, GraphQL::Types::String, required: false, description: 'Wiki page slug.'

      argument :project_id, ::Types::GlobalIDType[::Project],
        required: false,
        description: 'Wiki page project ID.'

      argument :namespace_id, ::Types::GlobalIDType[::Namespace],
        required: false,
        description: 'Wiki page namespace ID.'

      def resolve(slug: nil, namespace_id: nil, project_id: nil)
        if namespace_id.present? && project_id.present?
          raise Gitlab::Graphql::Errors::ArgumentError,
            'Only one of `namespace_id` or `project_id` are allowed.'
        end

        container = Namespace.find(extract_namespace_id(namespace_id)) if namespace_id.present?
        container = Project.find(extract_project_id(project_id)) if project_id.present?

        return unless slug.present? && container.present?

        ::WikiPage::Meta.find_by_canonical_slug(slug, container)
      end

      private

      def extract_project_id(gid)
        GitlabSchema.parse_gid(gid, expected_type: ::Project).model_id
      end

      def extract_namespace_id(gid)
        GitlabSchema.parse_gid(gid, expected_type: ::Namespace).model_id
      end
    end
  end
end
