# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Finders
    module Ci
      # todo: rename base_model to base_finder: https://gitlab.com/gitlab-org/gitlab/-/issues/559016
      class FinishedBuildsFinder < ::ClickHouse::Models::BaseModel
        include ActiveRecord::Sanitization::ClassMethods
        include Concerns::FinishedBuildsAggregations

        def self.table_name
          model_class.table_name
        end

        def self.model_class
          ::ClickHouse::Models::Ci::FinishedBuild
        end

        def execute
          ::ClickHouse::Client.select(query_builder, :main)
        end

        def for_project(project_id)
          where(project_id: project_id)
        end

        def select(*fields)
          fields = Array(fields).flatten.compact
          return self if fields.empty?

          validate_columns!(fields, :select)

          super.group_by(*fields)
        end

        def filter_by_job_name(term)
          where(query_builder[:name].matches("%#{sanitize_sql_like(term.downcase)}%"))
        end

        private

        def add_aggregation_select(expression, **)
          self.class.new(query_builder.select(expression))
        end

        def apply_order(field, direction)
          order(field, direction)
        end

        def apply_group(*columns)
          group(*columns)
        end

        def apply_pipeline_filter(pipelines)
          where(pipeline_id: pipelines.select(:id).query_builder)
        end
      end
    end
  end
end
