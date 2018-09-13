# frozen_string_literal: true

module Todos
  module Destroy
    class ProjectPrivateService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :project

      # rubocop: disable CodeReuse/ActiveRecord
      def initialize(project_id)
        @project = Project.find_by(id: project_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      override :todos
      # rubocop: disable CodeReuse/ActiveRecord
      def todos
        Todo.where(project_id: project.id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      override :project_ids
      def project_ids
        project.id
      end

      override :todos_to_remove?
      def todos_to_remove?
        project&.private?
      end
    end
  end
end
