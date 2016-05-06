module Banzai
  module ReferenceParser
    class UserParser < Parser
      self.reference_type = :user

      def referenced_by(nodes)
        group_ids = []
        user_ids = []
        project_ids = []

        nodes.each do |node|
          if node.has_attribute?('data-group')
            group_ids << node.attr('data-group').to_i
          elsif node.has_attribute?('data-user')
            user_ids << node.attr('data-user').to_i
          elsif node.has_attribute?('data-project')
            project_ids << node.attr('data-project').to_i
          end
        end

        find_users_for_groups(group_ids) | find_users(user_ids) |
          find_users_for_projects(project_ids)
      end

      def nodes_visible_to_user(user, nodes)
        group_attr = 'data-group'
        groups = grouped_objects_for_nodes(nodes, Group, group_attr)
        visible = []
        remaining = []

        nodes.each do |node|
          if node.has_attribute?(group_attr)
            node_group = groups[node.attr(group_attr).to_i]

            if node_group &&
              Ability.abilities.allowed?(user, :read_group, node_group)
              visible << node
            end
          # Remaining nodes will be processed by the parent class'
          # implementation of this method.
          else
            remaining << node
          end
        end

        visible + super(current_user, remaining)
      end

      def nodes_user_can_reference(current_user, nodes)
        project_attr = 'data-project'
        author_attr = 'data-author'

        projects = projects_for_nodes(nodes)
        users = grouped_objects_for_nodes(nodes, User, author_attr)

        nodes.select do |node|
          project_id = node.attr(project_attr)
          user_id = node.attr(author_attr)

          if project_id && user_id
            project = projects[project_id.to_i]
            user = users[user_id.to_i]

            project && user ? project.team.member?(user) : false
          else
            true
          end
        end
      end

      def find_users(ids)
        ids.empty? ? [] : User.where(id: ids).to_a
      end

      def find_users_for_groups(ids)
        if ids.empty?
          []
        else
          User.joins(:group_members).where(members: { source_id: ids }).to_a
        end
      end

      def find_users_for_projects(ids)
        if ids.empty?
          []
        else
          Project.where(id: ids).flat_map { |p| p.team.members.to_a }
        end
      end
    end
  end
end
