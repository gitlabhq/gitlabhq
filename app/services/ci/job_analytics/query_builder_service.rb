# frozen_string_literal: true

module Ci
  module JobAnalytics
    class QueryBuilderService
      attr_reader :project, :select_fields, :aggregations, :sort, :source, :ref, :from_time, :to_time, :name_search

      # @param project [Project] The project to find jobs for
      # @param options [Hash] Options for filtering and configuring the query builder
      # @option options [Array] :select_fields Fields to select
      # @option options [Array] :aggregations Aggregations to perform
      # @option options [String] :sort Sort order (ex. rate_of_success_asc)
      # @option options [String] :source Pipeline source
      # @option options [String] :ref Git reference
      # @option options [Time] :from_time Start time for filtering (defaults to 7 days ago)
      # @option options [Time] :to_time End time for filtering
      # @option options [String] :name_search Search by name of the pipeline jobs.
      def initialize(project, options = {})
        raise ArgumentError, 'project must be a valid Project instance' unless project.is_a?(Project)

        @project = project
        @select_fields = options[:select_fields] || []
        @aggregations = options[:aggregations] || []
        @sort = options[:sort]
        @source = options[:source]
        @ref = options[:ref]
        @from_time = options[:from_time] || 1.week.ago.utc
        @to_time = options[:to_time]
        @name_search = options[:name_search]
      end

      def execute
        unless ::Gitlab::ClickHouse.enabled_for_analytics?
          return ServiceResponse.error(message: 'ClickHouse database is not configured')
        end

        ServiceResponse.success(payload: { aggregate: build_finder.query_builder })
      end

      private

      def build_finder
        finder = ::ClickHouse::Finders::Ci::FinishedBuildsFinder.new
                                                                .for_project(project.id)
                                                                .select(*select_fields)
                                                                .select_aggregations(*aggregations)

        finder = finder.order_by(*extract_sort_info(sort)) if sort

        finder = finder.filter_by_job_name(name_search) if name_search

        finder.filter_by_pipeline_attrs(project: project,
          from_time: from_time,
          to_time: to_time,
          source: source,
          ref: ref
        )
      end

      def extract_sort_info(value)
        value.match(/(?<field>.*)_(?<dir>.*)/) => {field:, dir:}

        [field.to_sym, dir.to_sym]
      end
    end
  end
end
