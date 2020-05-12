# frozen_string_literal: true

module Types
  module AlertManagement
    class AlertSortEnum < SortEnum
      graphql_name 'AlertManagementAlertSort'
      description 'Values for sorting alerts'

      value 'START_TIME_ASC', 'Start time by ascending order', value: :start_time_asc
      value 'START_TIME_DESC', 'Start time by descending order', value: :start_time_desc
      value 'END_TIME_ASC', 'End time by ascending order', value: :end_time_asc
      value 'END_TIME_DESC', 'End time by descending order', value: :end_time_desc
      value 'CREATED_TIME_ASC', 'Created time by ascending order', value: :created_at_asc
      value 'CREATED_TIME_DESC', 'Created time by ascending order', value: :created_at_desc
      value 'UPDATED_TIME_ASC', 'Created time by ascending order', value: :updated_at_desc
      value 'UPDATED_TIME_DESC', 'Created time by ascending order', value: :updated_at_desc
      value 'EVENTS_COUNT_ASC', 'Events count by ascending order', value: :events_count_asc
      value 'EVENTS_COUNT_DESC', 'Events count by descending order', value: :events_count_desc
      value 'SEVERITY_ASC', 'Severity by ascending order', value: :severity_asc
      value 'SEVERITY_DESC', 'Severity by descending order', value: :severity_desc
      value 'STATUS_ASC', 'Status by ascending order', value: :status_asc
      value 'STATUS_DESC', 'Status by descending order', value: :status_desc
    end
  end
end
