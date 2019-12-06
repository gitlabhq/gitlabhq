# frozen_string_literal: true

module API
  module ProjectsBatchCounting
    extend ActiveSupport::Concern

    class_methods do
      # This adds preloading to the query and executes batch counting
      # Side-effect: The query will be executed during batch counting
      def preload_and_batch_count!(projects_relation)
        preload_relation(projects_relation).tap do |projects|
          execute_batch_counting(projects)
        end
      end

      def execute_batch_counting(projects)
        ::Projects::BatchForksCountService.new(forks_counting_projects(projects)).refresh_cache

        ::Projects::BatchOpenIssuesCountService.new(projects).refresh_cache
      end

      def forks_counting_projects(projects)
        projects
      end
    end
  end
end
