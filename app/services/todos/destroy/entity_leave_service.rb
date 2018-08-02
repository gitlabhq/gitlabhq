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
          Todo.where('(project_id IN (?) OR group_id IN (?)) AND user_id = ?', project_ids, group_ids, user_id)
        else
          project_ids.each do |project_id|
            TodosDestroyer::PrivateFeaturesWorker.perform_async(project_id, user_id)
          end

          Todo.where(
            target_id: confidential_issues.select(:id), target_type: Issue, user_id: user_id
          )
        end
      end

      override :project_ids
      def project_ids
        case entity
        when Project
          [entity.id]
        when Namespace
          Project.select(:id).where(namespace_id: group_ids)
        end
      end

      def group_ids
        case entity
        when Project
          []
        when Namespace
          entity.self_and_descendants.select(:id)
        end
      end

      override :todos_to_remove?
      def todos_to_remove?
        # if an entity is provided we want to check always at least private features
        !!entity
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
