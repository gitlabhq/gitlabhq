module API
  module ProjectsRelationBuilder
    extend ActiveSupport::Concern

    module ClassMethods
      def prepare_relation(projects_relation, options = {})
        projects_relation = preload_relation(projects_relation, options)
        execute_batch_counting(projects_relation)
        projects_relation
      end

      def preload_relation(projects_relation, options =  {})
        projects_relation
      end

      def forks_counting_projects(projects_relation)
        projects_relation
      end

      def batch_forks_counting(projects_relation)
        ::Projects::BatchForksCountService.new(forks_counting_projects(projects_relation)).refresh_cache
      end

      def batch_open_issues_counting(projects_relation)
        ::Projects::BatchOpenIssuesCountService.new(projects_relation).refresh_cache
      end

      def execute_batch_counting(projects_relation)
        batch_forks_counting(projects_relation)
        batch_open_issues_counting(projects_relation)
      end
    end
  end
end
