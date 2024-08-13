# frozen_string_literal: true

module Types
  class MergeRequestReviewStateEnum < BaseEnum
    graphql_name 'MergeRequestReviewState'
    description 'State of a review of a GitLab merge request.'

    value 'UNREVIEWED', value: 'unreviewed',
      description: 'Awaiting review from merge request reviewer.'
    value 'REVIEWED', value: 'reviewed',
      description: 'Merge request reviewer has reviewed.'
    value 'REQUESTED_CHANGES', value: 'requested_changes',
      description: 'Merge request reviewer has requested changes.'
    value 'APPROVED', value: 'approved',
      description: 'Merge request reviewer has approved the changes.'
    value 'UNAPPROVED', value: 'unapproved',
      description: 'Merge request reviewer removed their approval of the changes.'
    value 'REVIEW_STARTED', value: 'review_started',
      description: 'Merge request reviewer has started a review.'
  end
end
