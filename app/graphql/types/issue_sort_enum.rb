# frozen_string_literal: true

module Types
  class IssueSortEnum < IssuableSortEnum
    graphql_name 'IssueSort'
    description 'Values for sorting issues'

    value 'DUE_DATE_ASC', 'Due date by ascending order.', value: :due_date_asc
    value 'DUE_DATE_DESC', 'Due date by descending order.', value: :due_date_desc
    value 'RELATIVE_POSITION_ASC', 'Relative position by ascending order.', value: :relative_position_asc
    value 'SEVERITY_ASC', 'Severity from less critical to more critical.', value: :severity_asc
    value 'SEVERITY_DESC', 'Severity from more critical to less critical.', value: :severity_desc
    value 'TITLE_ASC', 'Title by ascending order.', value: :title_asc
    value 'TITLE_DESC', 'Title by descending order.', value: :title_desc
    value 'POPULARITY_ASC', 'Number of upvotes (awarded "thumbs up" emoji) by ascending order.', value: :popularity_asc
    value 'POPULARITY_DESC', 'Number of upvotes (awarded "thumbs up" emoji) by descending order.', value: :popularity_desc
    value 'ESCALATION_STATUS_ASC', 'Status from triggered to resolved.', value: :escalation_status_asc
    value 'ESCALATION_STATUS_DESC', 'Status from resolved to triggered.', value: :escalation_status_desc
    value 'CLOSED_AT_ASC', 'Closed time by ascending order.', value: :closed_at_asc
    value 'CLOSED_AT_DESC', 'Closed time by descending order.', value: :closed_at_desc
  end
end

Types::IssueSortEnum.prepend_mod_with('Types::IssueSortEnum')
