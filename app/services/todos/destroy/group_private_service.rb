module Todos
  module Destroy
    class GroupPrivateService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :group

      def initialize(group_id)
        @group = Group.find_by(id: group_id)
      end

      private

      override :todos
      def todos
        Todo.where(group_id: group.id)
      end

      override :authorized_users
      def authorized_users
        GroupMember.select(:user_id).where(source: group.id)
      end

      override :todos_to_remove?
      def todos_to_remove?
        group&.private?
      end
    end
  end
end
