module Todos
  module Destroy
    class ProjectPrivateService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :project

      def initialize(project_id)
        @project = Project.find_by(id: project_id)
      end

      def execute
        Issue.where(project_id: project_ids, confidential: true).each do |issue|
          TodosDestroyer::ConfidentialIssueWorker.perform_async(issue.id)
        end

        super
      end

      private

      override :todos
      def todos
        Todo.where(project_id: project_ids)
      end

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
