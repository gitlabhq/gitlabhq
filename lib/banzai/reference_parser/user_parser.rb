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

      def user_can_see_reference?(user, node)
        if node.has_attribute?('data-group')
          group = Group.find_by(id: node.attr('data-group'))
          Ability.abilities.allowed?(user, :read_group, group)
        else
          super
        end
      end

      def user_can_reference?(user, node)
        # Only team members can reference `@all`
        if node.has_attribute?('data-project')
          project = Project.find_by(id: node.attr('data-project'))
          return false unless project

          user && project.team.member?(user)
        else
          super
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
