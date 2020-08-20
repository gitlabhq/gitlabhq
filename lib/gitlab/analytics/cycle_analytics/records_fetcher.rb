# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class RecordsFetcher
        include Gitlab::Utils::StrongMemoize
        include StageQueryHelpers
        include Gitlab::CycleAnalytics::MetricsTables

        MAX_RECORDS = 20

        MAPPINGS = {
          Issue => {
            serializer_class: AnalyticsIssueSerializer,
            includes_for_query: { project: { namespace: [:route] }, author: [] },
            columns_for_select: %I[title iid id created_at author_id project_id]
          },
          MergeRequest => {
            serializer_class: AnalyticsMergeRequestSerializer,
            includes_for_query: { target_project: [:namespace], author: [] },
            columns_for_select: %I[title iid id created_at author_id state_id target_project_id]
          }
        }.freeze

        delegate :subject_class, to: :stage

        def initialize(stage:, query:, params: {})
          @stage = stage
          @query = query
          @params = params
        end

        def serialized_records
          strong_memoize(:serialized_records) do
            # special case (legacy): 'Test' and 'Staging' stages should show Ci::Build records
            if default_test_stage? || default_staging_stage?
              AnalyticsBuildSerializer.new.represent(ci_build_records.map { |e| e['build'] })
            else
              records.map do |record|
                project = record.project
                attributes = record.attributes.merge({
                  project_path: project.path,
                  namespace_path: project.namespace.route.path,
                  author: record.author
                })
                serializer.represent(attributes)
              end
            end
          end
        end

        private

        attr_reader :stage, :query, :params

        def columns
          MAPPINGS.fetch(subject_class).fetch(:columns_for_select).map do |column_name|
            subject_class.arel_table[column_name]
          end
        end

        def default_test_stage?
          stage.matches_with_stage_params?(Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_test_stage)
        end

        def default_staging_stage?
          stage.matches_with_stage_params?(Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_staging_stage)
        end

        def serializer
          MAPPINGS.fetch(subject_class).fetch(:serializer_class).new
        end

        # Loading Ci::Build records instead of MergeRequest records
        # rubocop: disable CodeReuse/ActiveRecord
        def ci_build_records
          ci_build_join = mr_metrics_table
            .join(build_table)
            .on(mr_metrics_table[:pipeline_id].eq(build_table[:commit_id]))
            .join_sources

          q = ordered_and_limited_query
            .joins(ci_build_join)
            .select(build_table[:id], *time_columns)

          results = execute_query(q).to_a

          Gitlab::CycleAnalytics::Updater.update!(results, from: 'id', to: 'build', klass: ::Ci::Build.includes({ project: [:namespace], user: [], pipeline: [] }))
        end

        def ordered_and_limited_query
          order_by_end_event(query, columns).limit(MAX_RECORDS)
        end

        def records
          results = ordered_and_limited_query
            .select(*columns, *time_columns)

          # using preloader instead of includes to avoid AR generating a large column list
          ActiveRecord::Associations::Preloader.new.preload(
            results,
            MAPPINGS.fetch(subject_class).fetch(:includes_for_query)
          )

          results
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def time_columns
          [
            stage.start_event.timestamp_projection.as('start_event_timestamp'),
            stage.end_event.timestamp_projection.as('end_event_timestamp'),
            round_duration_to_seconds.as('total_time')
          ]
        end
      end
    end
  end
end

Gitlab::Analytics::CycleAnalytics::RecordsFetcher.prepend_if_ee('EE::Gitlab::Analytics::CycleAnalytics::RecordsFetcher')
