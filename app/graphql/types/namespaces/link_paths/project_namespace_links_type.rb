# frozen_string_literal: true

module Types
  module Namespaces
    module LinkPaths
      class ProjectNamespaceLinksType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'ProjectNamespaceLinks'
        implements ::Types::Namespaces::LinkPaths

        field :new_work_item_email_address,
          GraphQL::Types::String,
          null: true,
          description: 'Email address that can be used to create a new work item in this project. ' \
            'Returns null if incoming email is not configured. More details on how to configure incoming email ' \
            'is in this [documentation](https://docs.gitlab.com/administration/incoming_email/#set-it-up).'

        def issues_list
          url_helpers.project_issues_path(project)
        end

        def labels_manage
          url_helpers.project_labels_path(project)
        end

        def new_project
          url_helpers.new_project_path(namespace_id: group&.id)
        end

        def new_comment_template
          url_helpers.new_comment_template_paths(group, project)
        end

        def contribution_guide_path
          return unless project&.repository

          ::ProjectPresenter.new(project).contribution_guide_path
        end

        def new_work_item_email_address
          project.new_issuable_address(current_user, 'issue')
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

::Types::Namespaces::LinkPaths::ProjectNamespaceLinksType.prepend_mod
