# frozen_string_literal: true

module Todos
  module Destroy
    class ProjectPrivateService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :project

      def initialize(project_id)
        @project = Project.find_by_id(project_id)
      end

      def execute
        return unless todos_to_remove?

        delete_todos
      end

      private

      def delete_todos
        authorized_users = ProjectAuthorization.select(:user_id).for_project(project_ids)

        todos.not_in_users(authorized_users).delete_all
      end

      def todos
        Todo.for_project(project.id)
      end

      def project_ids
        project.id
      end

      def todos_to_remove?
        project&.private?
      end
    end
  end
end
