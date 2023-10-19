# frozen_string_literal: true

module Todos
  module Destroy
    class UnauthorizedFeaturesService < ::Todos::Destroy::BaseService
      attr_reader :project_id, :user_id

      BATCH_SIZE = 1000

      def initialize(project_id, user_id = nil)
        @project_id = project_id
        @user_id = user_id
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        return if user_id && authorized_users.where(user_id: user_id).exists?

        related_todos.each_batch(of: BATCH_SIZE) do |batch|
          pending_delete = without_authorized(batch).includes(:target, :user).reject do |todo|
            Ability.allowed?(todo.user, :read_todo, todo, scope: :user)
          end
          Todo.where(id: pending_delete).delete_all if pending_delete.present?
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def without_authorized(items)
        items.not_in_users(authorized_users)
      end

      def authorized_users
        ProjectAuthorization.select(:user_id).for_project(project_ids)
      end

      def related_todos
        base_scope = Todo.for_project(project_id)
        base_scope = base_scope.for_user(user_id) if user_id
        base_scope
      end

      # Compatibility for #authorized_users in this class we always work
      # with 1 project for queries efficiency
      def project_ids
        [project_id]
      end
    end
  end
end
