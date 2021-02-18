# frozen_string_literal: true

class MergeRequestReviewer < ApplicationRecord
  enum state: {
    unreviewed: 0,
    reviewed: 1
  }

  validates :state,
    presence: true,
    inclusion: { in: MergeRequestReviewer.states.keys }

  belongs_to :merge_request
  belongs_to :reviewer, class_name: 'User', foreign_key: :user_id, inverse_of: :merge_request_reviewers
end
