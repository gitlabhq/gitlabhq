# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Models
    module Ci
      class FinishedPipelinesBase < ClickHouse::Models::BaseModel
        def self.for_project(project)
          new.for_project(project)
        end

        def self.by_status(statuses)
          new.by_status(statuses)
        end

        def self.group_by_status
          new.group_by_status
        end

        def for_project(project)
          where(path: project.project_namespace.traversal_path)
        end

        def by_status(statuses)
          where(status: statuses)
        end

        def group_by_status
          group([@query_builder.table[:status]])
        end

        def count_pipelines_function
          Arel::Nodes::NamedFunction.new('countMerge', [@query_builder.table[:count_pipelines]])
        end
      end
    end
  end
end
