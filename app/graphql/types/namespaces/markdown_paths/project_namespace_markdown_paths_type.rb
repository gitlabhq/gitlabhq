# frozen_string_literal: true

module Types
  module Namespaces
    module MarkdownPaths
      class ProjectNamespaceMarkdownPathsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'ProjectNamespaceMarkdownPaths'
        implements ::Types::Namespaces::MarkdownPaths

        def uploads_path
          url_helpers.project_uploads_path(project)
        end

        def markdown_preview_path(iid: nil)
          url_helpers.project_preview_markdown_path(project, target_type: 'WorkItem', target_id: iid)
        end

        def autocomplete_sources_path(iid: nil, work_item_type_id: nil)
          params = build_autocomplete_params(iid: iid, work_item_type_id: work_item_type_id)

          {
            members: url_helpers.members_project_autocomplete_sources_path(project, params),
            issues: url_helpers.issues_project_autocomplete_sources_path(project, params),
            merge_requests: url_helpers.merge_requests_project_autocomplete_sources_path(project, params),
            labels: url_helpers.labels_project_autocomplete_sources_path(project, params),
            milestones: url_helpers.milestones_project_autocomplete_sources_path(project, params),
            commands: url_helpers.commands_project_autocomplete_sources_path(project, params),
            snippets: url_helpers.snippets_project_autocomplete_sources_path(project, params),
            contacts: url_helpers.contacts_project_autocomplete_sources_path(project, params),
            wikis: url_helpers.wikis_project_autocomplete_sources_path(project, params)
          }
        end

        def project
          @project ||= object.project
        end
      end
    end
  end
end

::Types::Namespaces::MarkdownPaths::ProjectNamespaceMarkdownPathsType.prepend_mod
