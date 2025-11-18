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

        field :releases_path,
          GraphQL::Types::String,
          null: true,
          description: 'Project releases path.'

        field :project_import_jira_path,
          GraphQL::Types::String,
          null: true,
          description: 'JIRA import path.'

        field :export_csv_path,
          GraphQL::Types::String,
          null: true,
          description: 'CSV export endpoint for work items.',
          fallback_value: nil,
          experiment: { milestone: '18.6' }

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

        def releases_path
          url_helpers.project_releases_path(project, format: :json)
        end

        def project_import_jira_path
          url_helpers.project_import_jira_path(project)
        end

        def rss_path
          base_path = url_helpers.project_work_items_path(project)
          url_helpers.project_work_items_path(project, url_helpers.feed_url_options(:atom, base_path))
        end

        def calendar_path
          base_path = url_helpers.project_work_items_path(project)
          url_helpers.project_work_items_path(project, url_helpers.feed_url_options(:ics, base_path))
        end

        def namespace_full_path
          project.namespace.full_path
        end

        def export_csv_path
          url_helpers.export_csv_project_issues_path(project)
        end

        def new_issue_path
          url_helpers.new_project_issue_path(project)
        end

        def group_path
          group&.full_path
        end

        def issues_list_path
          url_helpers.project_issues_path(project)
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
