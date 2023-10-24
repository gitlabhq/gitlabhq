# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class UserParser < BaseParser
      self.reference_type = :user

      def referenced_by(nodes, options = {})
        group_ids = Set.new
        user_ids = Set.new
        project_ids = Set.new

        nodes.each do |node|
          if node.has_attribute?('data-group')
            group_ids << node.attr('data-group').to_i
          elsif node.has_attribute?(self.class.data_attribute)
            user_ids << node.attr(self.class.data_attribute).to_i
          elsif node.has_attribute?('data-project')
            project_ids << node.attr('data-project').to_i
          end
        end

        user_ids += find_user_ids_for_groups(group_ids)
        user_ids += find_user_ids_for_projects(project_ids)

        find_users(user_ids)
      end

      def nodes_visible_to_user(user, nodes)
        group_attr = 'data-group'
        groups = lazy { grouped_objects_for_nodes(nodes, Group, group_attr) }
        visible = []
        remaining = []

        nodes.each do |node|
          if node.has_attribute?(group_attr)
            next unless can_read_group_reference?(node, user, groups)

            visible << node
          elsif can_read_project_reference?(node)
            visible << node
          else
            remaining << node
          end
        end

        # If project does not belong to a group
        # and does not have the same project id as the current project
        # base class will check if user can read the project that contains
        # the user reference.
        visible + super(current_user, remaining)
      end

      def nodes_user_can_reference(current_user, nodes)
        project_attr = 'data-project'
        author_attr = 'data-author'

        projects = lazy { projects_for_nodes(nodes) }
        users = lazy { grouped_objects_for_nodes(nodes, User, author_attr) }

        nodes.select do |node|
          project_id = node.attr(project_attr)
          user_id = node.attr(author_attr)
          project = project_for_node(node)

          if project && project_id && project.id == project_id.to_i
            true
          elsif project_id && user_id
            project = projects[node]
            user = users[node]

            project&.member?(user)
          else
            true
          end
        end
      end

      private

      # Check if project belongs to a group which
      # user can read.
      def can_read_group_reference?(node, user, groups)
        node_group = groups[node]

        node_group && can?(user, :read_group, node_group)
      end

      def can_read_project_reference?(node)
        node_id = node.attr('data-project').to_i

        project_for_node(node)&.id == node_id
      end

      def find_users(ids)
        return [] if ids.empty?

        collection_objects_for_ids(User, ids)
      end

      def find_user_ids_for_groups(group_ids)
        return [] if group_ids.empty?

        GroupMember
          .of_groups(Group.id_in(group_ids).where('mentions_disabled IS NOT TRUE'))
          .non_request
          .non_invite
          .non_minimal_access
          .distinct
          .pluck(:user_id)
      end

      def find_user_ids_for_projects(project_ids)
        return [] if project_ids.empty?

        ProjectAuthorization.for_project(project_ids).pluck(:user_id)
      end

      def can_read_reference?(user, ref_project, node)
        can?(user, :read_project, ref_project)
      end
    end
  end
end
