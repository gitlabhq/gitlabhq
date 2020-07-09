# frozen_string_literal: true

module API
  module ProjectsRelationBuilder
    extend ActiveSupport::Concern

    class_methods do
      def prepare_relation(projects_relation, options = {})
        projects_relation = preload_relation(projects_relation, options)
        execute_batch_counting(projects_relation)
        # Call the forks count method on every project, so the BatchLoader would load them all at
        # once when the entities are rendered
        projects_relation.each(&:forks_count)

        projects_relation
      end

      def preload_relation(projects_relation, options = {})
        projects_relation
      end

      def forks_counting_projects(projects_relation)
        projects_relation
      end

      def batch_open_issues_counting(projects_relation)
        ::Projects::BatchOpenIssuesCountService.new(projects_relation).refresh_cache
      end

      def execute_batch_counting(projects_relation)
        batch_open_issues_counting(projects_relation)
      end
    end
  end
end
