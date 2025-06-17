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

        def autocomplete_sources_path(autocomplete_type:, iid: nil, work_item_type_id: nil)
          params = build_autocomplete_params(iid: iid, work_item_type_id: work_item_type_id)

          case autocomplete_type
          when 'members'
            url_helpers.members_group_autocomplete_sources_path(group, params)
          when 'issues'
            url_helpers.issues_group_autocomplete_sources_path(group, params)
          when 'merge_requests'
            url_helpers.merge_requests_group_autocomplete_sources_path(group, params)
          when 'labels'
            url_helpers.labels_group_autocomplete_sources_path(group, params)
          when 'milestones'
            url_helpers.milestones_group_autocomplete_sources_path(group, params)
          when 'commands'
            url_helpers.commands_group_autocomplete_sources_path(group, params)
          end
        end
      end
    end
  end
end
