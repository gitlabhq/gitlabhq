# frozen_string_literal: true

module Todos
  module Destroy
    class GroupPrivateService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :group

      def initialize(group_id)
        @group = Group.find_by_id(group_id)
      end

      def execute
        return unless todos_to_remove?

        delete_todos
      end

      private

      def delete_todos
        authorized_users = User.from_union([
          group.project_users_with_descendants.select(:id),
          group.members_with_parents.select(:user_id)
        ], remove_duplicates: false)

        todos.not_in_users(authorized_users).delete_all
      end

      def todos
        Todo.for_group(group.id)
      end

      def todos_to_remove?
        group&.private?
      end
    end
  end
end
