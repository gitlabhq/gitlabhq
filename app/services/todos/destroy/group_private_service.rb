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
        authorized_users = Member.from_union(
          [
            group.descendant_project_members_with_inactive.select(:user_id),
            group.members_with_parents.select(:user_id)
          ],
          remove_duplicates: false
        ).select(:user_id)

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
