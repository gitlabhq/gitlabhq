# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class ErrorTrackingType < BaseObject
        graphql_name 'WorkItemWidgetErrorTracking'
        description 'Represents the error tracking widget'

        implements ::Types::WorkItems::WidgetInterface

        field :identifier, GraphQL::Types::BigInt, null: true,
          description: 'Error tracking issue id.' \
            'This field can only be resolved for one work item in any single request.',
          method: :sentry_issue_identifier do
            extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
          end

        field :stack_trace, ::Types::WorkItems::Widgets::ErrorTracking::StackTraceType.connection_type,
          null: true,
          description: 'Stack trace details of the error.' \
            'This field can only be resolved for one work item in any single request.' do
          extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
        end

        field :status, ErrorTrackingStatusEnum, null: true,
          description: 'Response status of error service.' \
            'This field can only be resolved for one work item in any single request.' do
              extension(::Gitlab::Graphql::Limit::FieldCallCount, limit: 1)
            end

        def stack_trace
          return [] if object.sentry_issue_identifier.nil?

          if latest_event_result[:status] == :success
            Gitlab::ErrorTracking::StackTraceHighlightDecorator
              .decorate(latest_event_result[:latest_event])
              .stack_trace_entries
          else
            []
          end
        end

        def status
          return :not_found if object.sentry_issue_identifier.nil?

          if latest_event_result[:status] == :success
            :success
          elsif latest_event_result[:http_status] == :no_content
            :retry
          else
            :error
          end
        end

        private

        def latest_event_result
          @latest_event ||= ::ErrorTracking::IssueLatestEventService
            .new(object.work_item.project, current_user, issue_id: object.sentry_issue_identifier)
            .execute
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
