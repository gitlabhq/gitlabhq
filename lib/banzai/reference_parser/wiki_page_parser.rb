# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class WikiPageParser < BaseParser
      self.reference_type = :wiki_page

      def nodes_visible_to_user(user, nodes)
        project_attr = 'data-project'
        group_attr = 'data-group'

        projects = lazy { projects_for_nodes(nodes) }
        groups = lazy { grouped_objects_for_nodes(nodes, Group, group_attr) }

        preload_associations(projects, user)

        nodes.select do |node|
          if node.has_attribute?(project_attr)
            can_read_reference?(user, projects[node], node)
          elsif node.has_attribute?(group_attr)
            can_read_reference?(user, groups[node], node)
          else
            true
          end
        end
      end

      private

      def can_read_reference?(user, project_or_group, _node)
        can?(user, :read_wiki, project_or_group)
      end
    end
  end
end
