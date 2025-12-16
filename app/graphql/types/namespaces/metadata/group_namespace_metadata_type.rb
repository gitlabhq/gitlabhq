# frozen_string_literal: true

module Types
  module Namespaces
    module Metadata
      class GroupNamespaceMetadataType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'GroupNamespaceMetadata'
        implements ::Types::Namespaces::Metadata

        field :has_projects,
          GraphQL::Types::Boolean,
          null: true,
          resolver_method: :has_projects?,
          description: 'Whether the group has any projects.',
          experiment: { milestone: '18.6' }

        alias_method :group, :object

        def issue_repositioning_disabled?
          group.root_ancestor.issue_repositioning_disabled?
        end

        def show_new_work_item?
          return false if group.self_or_ancestors_archived?

          can?(current_user, :create_work_item, group)
        end

        def has_projects?
          GroupProjectsFinder.new(group: group, current_user: current_user).execute.exists?
        end

        def group_id
          group.id.to_s
        end
      end
    end
  end
end
