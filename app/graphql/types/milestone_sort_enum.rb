# frozen_string_literal: true

module Types
  class MilestoneSortEnum < SortEnum
    graphql_name 'MilestoneSort'
    description 'Values for sorting milestones'

    value 'DUE_DATE_ASC', 'Milestone due date by ascending order.', value: :due_date_asc
    value 'DUE_DATE_DESC', 'Milestone due date by descending order.', value: :due_date_desc
    value 'EXPIRED_LAST_DUE_DATE_ASC',
      value: :expired_last_due_date_asc,
      description: 'Group milestones in the order: non-expired milestones with due dates, non-expired milestones ' \
        'without due dates and expired milestones then sort by due date in ascending order.'
    value 'EXPIRED_LAST_DUE_DATE_DESC',
      value: :expired_last_due_date_desc,
      description: 'Group milestones in the order: non-expired milestones with due dates, non-expired milestones ' \
        'without due dates and expired milestones then sort by due date in descending order.'
  end
end
