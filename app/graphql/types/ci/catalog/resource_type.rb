# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      # rubocop: disable Graphql/AuthorizeTypes
      class ResourceType < BaseObject
        graphql_name 'CiCatalogResource'

        connection_type_class(Types::CountableConnectionType)

        field :id, GraphQL::Types::ID, null: false, description: 'ID of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :name, GraphQL::Types::String, null: true, description: 'Name of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :description, GraphQL::Types::String, null: true, description: 'Description of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :icon, GraphQL::Types::String, null: true, description: 'Icon for the catalog resource.',
          method: :avatar_path, alpha: { milestone: '15.11' }

        field :web_path, GraphQL::Types::String, null: true, description: 'Web path of the catalog resource.',
          alpha: { milestone: '16.1' }

        field :versions, Types::ReleaseType.connection_type, null: true,
          description: 'Versions of the catalog resource.',
          resolver: Resolvers::ReleasesResolver,
          alpha: { milestone: '16.1' }

        field :star_count, GraphQL::Types::Int, null: false,
          description: 'Number of times the catalog resource has been starred.',
          alpha: { milestone: '16.1' }

        field :forks_count, GraphQL::Types::Int, null: false, calls_gitaly: true,
          description: 'Number of times the catalog resource has been forked.',
          alpha: { milestone: '16.1' }

        field :root_namespace, Types::NamespaceType, null: true,
          description: 'Root namespace of the catalog resource.',
          alpha: { milestone: '16.1' }

        markdown_field :readme_html, null: false

        def web_path
          ::Gitlab::Routing.url_helpers.project_path(object.project)
        end

        def forks_count
          BatchLoader::GraphQL.wrap(object.forks_count)
        end

        def root_namespace
          BatchLoader::GraphQL.for(object.project_id).batch do |project_ids, loader|
            projects = Project.id_in(project_ids)

            # This preloader uses traversal_ids to obtain Group-type root namespaces.
            # It also preloads each project's immediate parent namespace, which effectively
            # preloads the User-type root namespaces since they cannot be nested (parent == root).
            Preloaders::ProjectRootAncestorPreloader.new(projects, :group).execute
            root_namespaces = projects.map(&:root_ancestor)

            # NamespaceType requires the `:read_namespace` ability. We must preload the policy for
            # Group-type namespaces to avoid N+1 queries caused by the authorization requests.
            group_root_namespaces = root_namespaces.select { |n| n.type == ::Group.sti_name }
            Preloaders::GroupPolicyPreloader.new(group_root_namespaces, current_user).execute

            # For User-type namespaces, the authorization request requires preloading the owner objects.
            user_root_namespaces = root_namespaces.select { |n| n.type == ::Namespaces::UserNamespace.sti_name }
            ActiveRecord::Associations::Preloader.new(records: user_root_namespaces, associations: :owner).call

            projects.each { |project| loader.call(project.id, project.root_ancestor) }
          end
        end

        def readme_html_resolver
          ::MarkupHelper.markdown(object.project.repository.readme&.data, context.to_h.dup)
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
