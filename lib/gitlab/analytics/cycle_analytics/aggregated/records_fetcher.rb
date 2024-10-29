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
              columns_for_select: %I[title iid id created_at author_id project_id],
              finder_class: IssuesFinder
            },
            MergeRequest => {
              serializer_class: AnalyticsMergeRequestSerializer,
              includes_for_query: { target_project: [:namespace], author: [] },
              columns_for_select: %I[title iid id created_at author_id state_id target_project_id],
              finder_class: MergeRequestsFinder
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
              # used in ORDER BY statement would be selected by Arel.star operation
              selections = [stage_event_model.arel_table[Arel.star]]

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
                  total_time: record.total_time,
                  start_event_timestamp: record.start_event_timestamp,
                  end_event_timestamp: record.end_event_timestamp
                })
                serializer.represent(attributes)
              end
            end
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def records_for_graphql
            # Convert duration milliseconds to seconds to be compatible with non-aggregated data format
            extra_columns_to_select = ['duration_in_milliseconds / 1000 AS total_time']

            preloads_for_issuable = MAPPINGS.fetch(subject_class).fetch(:includes_for_query)

            query
              .limit(MAX_RECORDS)
              .select(stage_event_model.arel_table[Arel.star], extra_columns_to_select)
              .preload(issuable: preloads_for_issuable)
          end
          # rubocop: enable CodeReuse/ActiveRecord

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

            issuables_by_id = finder.execute.id_in(stage_event_records_by_issuable_id.keys).index_by(&:id)

            stage_event_records_by_issuable_id.map do |issuable_id, record|
              [issuables_by_id[issuable_id], record] if issuables_by_id[issuable_id]
            end.compact
          end

          def finder
            MAPPINGS.fetch(subject_class).fetch(:finder_class).new(params[:current_user])
          end

          def serializer
            MAPPINGS.fetch(subject_class).fetch(:serializer_class).new
          end

          def preload_associations(records)
            ActiveRecord::Associations::Preloader.new(
              records: records,
              associations: MAPPINGS.fetch(subject_class).fetch(:includes_for_query)
            ).call

            records
          end
        end
      end
    end
  end
end
