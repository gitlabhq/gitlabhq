# frozen_string_literal: true

module Types
  module Namespaces
    module Metadata
      class ProjectNamespaceMetadataType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'ProjectNamespaceMetadata'
        implements ::Types::Namespaces::Metadata

        field :default_branch,
          GraphQL::Types::String,
          null: true,
          description: 'Default branch of the project.',
          fallback_value: nil,
          calls_gitaly: true,
          experiment: { milestone: '18.6' }

        def default_branch
          project.default_branch_or_main
        end

        def issue_repositioning_disabled?
          project.root_namespace.issue_repositioning_disabled?
        end

        def show_new_work_item?
          return false if project.self_or_ancestors_archived?

          # We want to show the link to users that are not signed in, that way they
          # get directed to the sign-in/sign-up flow and afterwards to the new issue page.
          # Note that we do this only for the project issues page
          return true unless current_user

          can?(current_user, :create_work_item, project)
        end

        def group_id
          group&.id&.to_s
        end

        private

        def project
          @project ||= object.project
        end

        def group
          @group ||= project.group
        end
      end
    end
  end
end
