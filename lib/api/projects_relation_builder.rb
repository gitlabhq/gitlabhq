# frozen_string_literal: true

module API
  module ProjectsRelationBuilder
    extend ActiveSupport::Concern

    class_methods do
      def prepare_relation(projects_relation, options = {})
        projects_relation = preload_relation(projects_relation, options)

        execute_batch_counting(projects_relation)

        projects_relation
      end

      # This is overridden by the specific Entity class to
      # preload assocations that it needs
      def preload_relation(projects_relation, options = {})
        projects_relation
      end

      # This is overridden by the specific Entity class to
      # batch load certain counts
      def execute_batch_counting(projects_relation)
      end
    end
  end
end
