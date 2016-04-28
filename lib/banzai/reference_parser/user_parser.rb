module Banzai
  module ReferenceParser
    class UserParser < Parser
      self.reference_type = :user

      def referenced_by(node)
        if node.has_attribute?('data-group')
          group = Group.find_by(id: node.attr('data-group'))

          group ? group.users : []
        elsif node.has_attribute?('data-user')
          [LazyReference.new(User, node.attr('data-user'))]
        elsif node.has_attribute?('data-project')
          project = Project.find_by(id: node.attr('data-project'))

          project ? project.team.members : []
        end
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
    end
  end
end
