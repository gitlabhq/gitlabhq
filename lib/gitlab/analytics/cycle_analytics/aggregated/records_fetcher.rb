# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Aggregated
        class RecordsFetcher
          include Gitlab::Utils::StrongMemoize
          include StageQueryHelpers

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

          def initialize(stage:, query:, params: {})
            @stage = stage
            @query = query
            @params = params
            @sort = params[:sort] || :end_event
            @direction = params[:direction] || :desc
            @page = params[:page] || 1
            @per_page = MAX_RECORDS
            @stage_event_model = query.model
          end

          def serialized_records
            strong_memoize(:serialized_records) do
              # When RecordsFetcher is used with query sourced from
              # InOperatorOptimization::QueryBuilder only columns
              # used in ORDER BY statement would be selected by Arel.start operation
              selections = [stage_event_model.arel_table[Arel.star]]
              selections << duration_in_seconds.as('total_time') if params[:sort] != :duration # duration sorting already exposes this data

              records = limited_query.select(*selections)

              yield records if block_given?
              issuables_and_records = load_issuables(records)

              preload_associations(issuables_and_records.map(&:first))

              issuables_and_records.map do |issuable, record|
                project = issuable.project
                attributes = issuable.attributes.merge({
                  project_path: project.path,
                  namespace_path: project.namespace.route.path,
                  author: issuable.author,
                  total_time: record.total_time
                })
                serializer.represent(attributes)
              end
            end
          end

          def limited_query
            query
              .page(page)
              .per(per_page)
              .without_count
          end

          private

          attr_reader :stage, :query, :sort, :direction, :params, :page, :per_page, :stage_event_model

          delegate :subject_class, to: :stage

          def load_issuables(stage_event_records)
            stage_event_records_by_issuable_id = stage_event_records.index_by(&:issuable_id)

            issuable_model = stage_event_model.issuable_model
            issuables_by_id = issuable_model.id_in(stage_event_records_by_issuable_id.keys).index_by(&:id)

            stage_event_records_by_issuable_id.map do |issuable_id, record|
              [issuables_by_id[issuable_id], record] if issuables_by_id[issuable_id]
            end.compact
          end

          def serializer
            MAPPINGS.fetch(subject_class).fetch(:serializer_class).new
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def preload_associations(records)
            ActiveRecord::Associations::Preloader.new.preload(
              records,
              MAPPINGS.fetch(subject_class).fetch(:includes_for_query)
            )

            records
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
