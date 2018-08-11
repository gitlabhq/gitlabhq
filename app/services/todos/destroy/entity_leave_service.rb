# frozen_string_literal: true

module Todos
  module Destroy
    class EntityLeaveService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :user, :entity

      def initialize(user_id, entity_id, entity_type)
        unless %w(Group Project).include?(entity_type)
          raise ArgumentError.new("#{entity_type} is not an entity user can leave")
        end

        @user = User.find_by(id: user_id)
        @entity = entity_type.constantize.find_by(id: entity_id)
      end

      def execute
        return unless entity && user

        # if at least reporter, all entities including confidential issues can be accessed
        return if user_has_reporter_access?

        remove_confidential_issue_todos

        if entity.private?
          remove_project_todos
          remove_group_todos
        else
          enqueue_private_features_worker
        end
      end

      private

      def enqueue_private_features_worker
        project_ids.each do |project_id|
          TodosDestroyer::PrivateFeaturesWorker.perform_async(project_id, user.id)
        end
      end

      def remove_confidential_issue_todos
        Todo.where(
          target_id: confidential_issues.select(:id), target_type: Issue, user_id: user.id
        ).delete_all
      end

      def remove_project_todos
        Todo.where(project_id: non_authorized_projects, user_id: user.id).delete_all
      end

      def remove_group_todos
        Todo.where(group_id: non_authorized_groups, user_id: user.id).delete_all
      end

      override :project_ids
      def project_ids
        condition = case entity
                    when Project
                      { id: entity.id }
                    when Namespace
                      { namespace_id: non_member_groups }
                    end

        Project.where(condition).select(:id)
      end

      def non_authorized_projects
        project_ids.where('id NOT IN (?)', user.authorized_projects.select(:id))
      end

      def non_authorized_groups
        return [] unless entity.is_a?(Namespace)

        entity.self_and_descendants.select(:id)
          .where('id NOT IN (?)', GroupsFinder.new(user).execute.select(:id))
      end

      def non_member_groups
        entity.self_and_descendants.select(:id)
          .where('id NOT IN (?)', user.membership_groups.select(:id))
      end

      def user_has_reporter_access?
        return unless entity.is_a?(Namespace)

        entity.member?(User.find(user.id), Gitlab::Access::REPORTER)
      end

      def confidential_issues
        assigned_ids = IssueAssignee.select(:issue_id).where(user_id: user.id)
        authorized_reporter_projects = user
          .authorized_projects(Gitlab::Access::REPORTER).select(:id)

        Issue.where(project_id: project_ids, confidential: true)
          .where('project_id NOT IN(?)', authorized_reporter_projects)
          .where('author_id != ?', user.id)
          .where('id NOT IN (?)', assigned_ids)
      end
    end
  end
end
