module Todos
  module Destroy
    class BaseService
      def execute
        return unless todos_to_remove?

        without_authorized(todos).delete_all
      end

      private

      def without_authorized(items)
        items.where('user_id NOT IN (?)', authorized_users)
      end

      def authorized_users
        ProjectAuthorization.select(:user_id).where(project_id: project_ids)
      end

      def todos
        # overridden in subclasses
      end

      def project_ids
        # overridden in subclasses
      end

      def todos_to_remove?
        # overridden in subclasses
      end
    end
  end
end
