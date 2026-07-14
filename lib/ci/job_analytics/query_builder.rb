# frozen_string_literal: true

module Ci
  module JobAnalytics
    class QueryBuilder
      attr_reader :project, :current_user, :select_fields, :aggregations,
        :sort, :source, :ref, :from_time, :to_time, :name_search

      # @param project [Project] The project to find jobs for
      # @param options [Hash] options for filtering and configuring the query builder
      # @option options [Array] :select_fields Fields to select
      # @option options [Array] :aggregations Aggregations to perform
      # @option options [String] :sort Sort order (ex. rate_of_success_asc)
      # @option options [String] :source Pipeline source
      # @option options [String] :ref Git reference
      # @option options [Time] :from_time Start time for filtering (defaults to 7 days ago)
      # @option options [Time] :to_time End time for filtering
      # @option options [String] :name_search Search by name of the pipeline jobs.
      def initialize(project:, current_user:, options: {})
        @project = project
        @current_user = current_user
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
        return unless ::Gitlab::ClickHouse.enabled_for_analytics? && Ability.allowed?(current_user, :read_build,
          project)

        finder = build_finder

        return finder.final_query if returns_final_query?(finder)

        finder.query_builder
      end

      private

      def build_finder
        finder = scope_to_project(base_finder)

        finder = finder.with_stages(project) if siphon_finder?(finder) && stage_name_requested?

        finder = finder
          .select(*select_fields)
          .select_aggregations(*aggregations)

        finder = finder.order_by(*extract_sort_info(sort)) if sort

        finder = finder.filter_by_job_name(name_search) if name_search

        finder = apply_pipeline_attrs(finder)
        apply_time_filter(finder)
      end

      def base_finder
        return ::ClickHouse::Finders::Ci::SiphonFinishedBuildsFinder.new if use_siphon_finder?

        return ::ClickHouse::Finders::Ci::FinishedBuildsDeduplicatedFinder.new if use_deduplicated_finder?

        ::ClickHouse::Finders::Ci::FinishedBuildsFinder.new
      end

      # The siphon finder reads siphon_p_ci_builds, which has no stage_name column,
      # so it scopes by container, derives the date window from started_at, and needs
      # an explicit stages join. The legacy finders scope by project_id and resolve
      # stage_name from their own column, so each call site adapts accordingly.
      def scope_to_project(finder)
        return finder.for_container(project) if siphon_finder?(finder)

        finder.for_project(project.id)
      end

      def apply_pipeline_attrs(finder)
        scope = siphon_finder?(finder) ? { container: project } : { project: project }

        finder.filter_by_pipeline_attrs(**scope, from_time: from_time, to_time: to_time, source: source, ref: ref)
      end

      def apply_time_filter(finder)
        return finder.within_dates(from_time, to_time) if siphon_finder?(finder)

        finder.apply_finished_at_lower_bound(from_time)
      end

      # The stages join is needed whenever :stage_name is referenced, whether it is
      # selected or only sorted on. extract_sort_info parses the sort field, so a
      # 'stage_name_asc'/'stage_name_desc' sort resolves to :stage_name here too.
      def stage_name_requested?
        return true if select_fields.include?(:stage_name)

        sort.present? && extract_sort_info(sort).first == :stage_name
      end

      def siphon_finder?(finder)
        finder.is_a?(::ClickHouse::Finders::Ci::SiphonFinishedBuildsFinder)
      end

      def returns_final_query?(finder)
        finder.is_a?(::ClickHouse::Finders::Ci::FinishedBuildsDeduplicatedFinder) || siphon_finder?(finder)
      end

      def use_siphon_finder?
        ::Feature.enabled?(:job_analytics_siphon, project)
      end

      def use_deduplicated_finder?
        ::ClickHouse::MigrationSupport::CiFinishedBuildsConsistencyHelper.backfill_in_progress?
      end

      def extract_sort_info(value)
        value.match(/(?<field>.*)_(?<dir>.*)/) => { field:, dir: }

        [field.to_sym, dir.to_sym]
      end
    end
  end
end
