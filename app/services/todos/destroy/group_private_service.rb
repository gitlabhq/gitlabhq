# frozen_string_literal: true

module Todos
  module Destroy
    class GroupPrivateService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :group

      # rubocop: disable CodeReuse/ActiveRecord
      def initialize(group_id)
        @group = Group.find_by(id: group_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      override :todos
      # rubocop: disable CodeReuse/ActiveRecord
      def todos
        Todo.where(group_id: group.id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      override :authorized_users
      def authorized_users
        group.direct_and_indirect_users.select(:id)
      end

      override :todos_to_remove?
      def todos_to_remove?
        group&.private?
      end
    end
  end
end
