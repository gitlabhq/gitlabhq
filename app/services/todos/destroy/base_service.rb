# frozen_string_literal: true

module Todos
  module Destroy
    class BaseService
      def execute
        return unless todos_to_remove?

        without_authorized(todos).delete_all
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def without_authorized(items)
        items.where.not('todos.user_id' => authorized_users)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def authorized_users
        ProjectAuthorization.select(:user_id).where(project_id: project_ids)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def todos
        raise NotImplementedError
      end

      def project_ids
        raise NotImplementedError
      end

      def todos_to_remove?
        raise NotImplementedError
      end
    end
  end
end
