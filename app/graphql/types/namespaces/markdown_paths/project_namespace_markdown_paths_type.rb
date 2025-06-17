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

        def autocomplete_sources_path(autocomplete_type:, iid: nil, work_item_type_id: nil)
          params = build_autocomplete_params(iid: iid, work_item_type_id: work_item_type_id)

          case autocomplete_type
          when 'members'
            url_helpers.members_project_autocomplete_sources_path(project, params)
          when 'issues'
            url_helpers.issues_project_autocomplete_sources_path(project, params)
          when 'merge_requests'
            url_helpers.merge_requests_project_autocomplete_sources_path(project,
              params)
          when 'labels'
            url_helpers.labels_project_autocomplete_sources_path(project, params)
          when 'milestones'
            url_helpers.milestones_project_autocomplete_sources_path(project, params)
          when 'commands'
            url_helpers.commands_project_autocomplete_sources_path(project, params)
          when 'snippets'
            url_helpers.snippets_project_autocomplete_sources_path(project, params)
          when 'contacts'
            url_helpers.contacts_project_autocomplete_sources_path(project, params)
          when 'wikis'
            url_helpers.wikis_project_autocomplete_sources_path(project, params)
          end
        end

        private

        def project
          @project ||= object.project
        end
      end
    end
  end
end
