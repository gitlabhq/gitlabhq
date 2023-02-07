# frozen_string_literal: true

module API
  module Entities
    class ProjectWithAccess < Project
      expose :permissions do
        expose :project_access, using: Entities::ProjectAccess do |project, options|
          if options[:project_members]
            options[:project_members].find { |member| member.source_id == project.id }
          else
            project.member(options[:current_user])
          end
        end

        expose :group_access, using: Entities::GroupAccess do |project, options|
          if project.group
            if options[:group_members]
              options[:group_members].find { |member| member.source_id == project.namespace_id }
            else
              project.group.highest_group_member(options[:current_user])
            end
          end
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_relation(projects_relation, options = {})
        super(projects_relation, options)
      end

      def self.postload_relation(projects_relation, options = {})
        options[:project_members] = options[:current_user]
          .project_members
          .where(source_id: projects_relation.subquery(:id))
          .preload(:source, user: [notification_settings: :source])

        options[:group_members] = options[:current_user]
          .group_members
          .where(source_id: projects_relation.subquery(:namespace_id))
          .preload(:source, user: [notification_settings: :source])
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
