require 'gitlab/markdown'
require 'html/pipeline/filter'

module Gitlab
  module Markdown
    # HTML filter that removes references to records that the current user does
    # not have permission to view.
    #
    # Expected to be run in its own post-processing pipeline.
    #
    class RedactorFilter < HTML::Pipeline::Filter
      def call
        doc.css('a.gfm').each do |node|
          unless user_can_reference?(node)
            node.replace(node.text)
          end
        end

        doc
      end

      def user_can_reference?(node)
        if node.has_attribute?('data-group-id')
          user_can_reference_group?(node.attr('data-group-id'))
        elsif node.has_attribute?('data-project-id')
          user_can_reference_project?(node.attr('data-project-id'))
        elsif node.has_attribute?('data-user-id')
          user_can_reference_user?(node.attr('data-user-id'))
        else
          true
        end
      end

      def user_can_reference_group?(id)
        group = Group.find(id)

        group && can?(:read_group, group)
      rescue ActiveRecord::RecordNotFound
        false
      end

      def user_can_reference_project?(id)
        project = Project.find(id)

        project && can?(:read_project, project)
      rescue ActiveRecord::RecordNotFound
        false
      end

      def user_can_reference_user?(id)
        # Permit all user reference links
        true
      end

      private

      def abilities
        Ability.abilities
      end

      def can?(ability, object)
        abilities.allowed?(current_user, ability, object)
      end

      def current_user
        context[:current_user]
      end
    end
  end
end
