# frozen_string_literal: true

module Types
  module Namespaces
    module LinkPaths
      class ProjectNamespaceLinksType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'ProjectNamespaceLinks'
        implements ::Types::Namespaces::LinkPaths

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
          new_comment_template_paths(group, project)&.dig(0, :href)
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
