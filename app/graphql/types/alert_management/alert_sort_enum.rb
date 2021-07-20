# frozen_string_literal: true

module Types
  module AlertManagement
    class AlertSortEnum < SortEnum
      graphql_name 'AlertManagementAlertSort'
      description 'Values for sorting alerts'

      value 'STARTED_AT_ASC', 'Start time by ascending order.', value: :started_at_asc
      value 'STARTED_AT_DESC', 'Start time by descending order.', value: :started_at_desc
      value 'ENDED_AT_ASC', 'End time by ascending order.', value: :ended_at_asc
      value 'ENDED_AT_DESC', 'End time by descending order.', value: :ended_at_desc
      value 'CREATED_TIME_ASC', 'Created time by ascending order.', value: :created_at_asc
      value 'CREATED_TIME_DESC', 'Created time by descending order.', value: :created_at_desc
      value 'UPDATED_TIME_ASC', 'Created time by ascending order.', value: :updated_at_asc
      value 'UPDATED_TIME_DESC', 'Created time by descending order.', value: :updated_at_desc
      value 'EVENT_COUNT_ASC', 'Events count by ascending order.', value: :event_count_asc
      value 'EVENT_COUNT_DESC', 'Events count by descending order.', value: :event_count_desc
      value 'SEVERITY_ASC', 'Severity from less critical to more critical.', value: :severity_asc
      value 'SEVERITY_DESC', 'Severity from more critical to less critical.', value: :severity_desc
      value 'STATUS_ASC', 'Status by order: `Ignored > Resolved > Acknowledged > Triggered`.', value: :status_asc
      value 'STATUS_DESC', 'Status by order: `Triggered > Acknowledged > Resolved > Ignored`.', value: :status_desc
    end
  end
end
