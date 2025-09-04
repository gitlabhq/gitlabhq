# frozen_string_literal: true

module Types
  module Namespaces
    module MarkdownPaths
      class GroupNamespaceMarkdownPathsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'GroupNamespaceMarkdownPaths'
        implements ::Types::Namespaces::MarkdownPaths

        alias_method :group, :object

        def uploads_path
          url_helpers.group_uploads_path(group)
        end

        def markdown_preview_path(iid: nil)
          url_helpers.group_preview_markdown_path(group, target_type: 'WorkItem', target_id: iid)
        end

        def autocomplete_sources_path(iid: nil, work_item_type_id: nil)
          params = build_autocomplete_params(iid: iid, work_item_type_id: work_item_type_id)

          {
            members: url_helpers.members_group_autocomplete_sources_path(group, params),
            issues: url_helpers.issues_group_autocomplete_sources_path(group, params),
            mergeRequests: url_helpers.merge_requests_group_autocomplete_sources_path(group, params),
            labels: url_helpers.labels_group_autocomplete_sources_path(group, params),
            milestones: url_helpers.milestones_group_autocomplete_sources_path(group, params),
            commands: url_helpers.commands_group_autocomplete_sources_path(group, params)
          }
        end
      end
    end
  end
end

::Types::Namespaces::MarkdownPaths::GroupNamespaceMarkdownPathsType.prepend_mod
