module Todos
  module Destroy
    class EntityLeaveService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :user_id, :entity

      def initialize(user_id, entity_id, entity_type)
        unless %w(Group Project).include?(entity_type)
          raise ArgumentError.new("#{entity_type} is not an entity user can leave")
        end

        @user_id = user_id
        @entity = entity_type.constantize.find_by(id: entity_id)
      end

      def execute
        return unless entity
        # only reporters can see confidential issues
        return if has_reporter_permissions?

        if user_project_authorization
          remove_confidential_issue_todos
        else
          if entity.private?
            remove_project_todos
          else
            remove_confidential_issue_todos
            project_ids.each do |project_id|
              TodosDestroyer::PrivateFeaturesWorker.perform_async(project_id, user_id)
            end
          end
        end
      end

      private

      def user_project_authorization
        ProjectAuthorization.select(:user_id, :access_level)
          .where(project_id: project_ids, user_id: user_id).first
      end

      def has_reporter_permissions?
        return unless user_project_authorization

        user_project_authorization.access_level >= Gitlab::Access::REPORTER
      end

      def remove_project_todos
        Todo.where(project_id: project_ids, user_id: user_id).delete_all
      end

      override :project_ids
      def project_ids
        case entity
        when Project
          [entity.id]
        when Namespace
          Project.select(:id).where(namespace_id: entity.self_and_descendants.select(:id))
        end
      end

      def remove_confidential_issue_todos
        Todo.where(
          target_id: confidential_issues.select(:id), target_type: Issue, user_id: user_id
        ).delete_all
      end

      def confidential_issues
        assigned_ids = IssueAssignee.select(:issue_id).where(user_id: user_id)

        Issue.where(project_id: project_ids, confidential: true)
          .where('author_id != ?', user_id)
          .where('id NOT IN (?)', assigned_ids)
      end
    end
  end
end
