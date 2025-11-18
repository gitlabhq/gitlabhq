# frozen_string_literal: true

module Types
  module Namespaces
    module LinkPaths
      class GroupNamespaceLinksType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'GroupNamespaceLinks'
        implements ::Types::Namespaces::LinkPaths

        alias_method :group, :object

        def issues_list
          url_helpers.issues_group_path(group)
        end

        def labels_manage
          url_helpers.group_labels_path(group)
        end

        def new_project
          url_helpers.new_project_path(namespace_id: group&.id)
        end

        def report_abuse
          url_helpers.add_category_abuse_reports_path
        end

        def new_comment_template
          url_helpers.new_comment_template_paths(group)
        end

        def rss_path
          base_path = url_helpers.group_work_items_path(group)
          url_helpers.group_work_items_path(group, url_helpers.feed_url_options(:atom, base_path))
        end

        def calendar_path
          base_path = url_helpers.group_work_items_path(group)
          url_helpers.group_work_items_path(group, url_helpers.feed_url_options(:ics, base_path))
        end

        def namespace_full_path
          group.full_path
        end

        def group_path
          group.full_path
        end

        def issues_list_path
          url_helpers.issues_group_path(group)
        end
      end
    end
  end
end

::Types::Namespaces::LinkPaths::GroupNamespaceLinksType.prepend_mod
