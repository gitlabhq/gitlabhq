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

      private

      override :todos
      def todos
        if entity.private?
          Todo.where(project_id: project_ids, user_id: user_id)
        else
          Todo.where(target_id: confidential_issues.select(:id), target_type: Issue)
        end
      end

      override :project_ids
      def project_ids
        if entity.is_a?(Project)
          entity.id
        else
          Project.select(:id).where(namespace_id: entity.self_and_descendants.select(:id))
        end
      end

      override :todos_to_remove?
      def todos_to_remove?
        return unless entity

        entity.private? || confidential_issues.count > 0
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
