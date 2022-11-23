# frozen_string_literal: true

class MergeRequest::Predictions < ApplicationRecord  # rubocop:disable Style/ClassAndModuleChildren
  belongs_to :merge_request, inverse_of: :predictions

  validates :suggested_reviewers, json_schema: { filename: 'merge_request_predictions_suggested_reviewers' }
  validates :accepted_reviewers, json_schema: { filename: 'merge_request_predictions_accepted_reviewers' }

  def suggested_reviewer_usernames
    Array.wrap(suggested_reviewers['reviewers'])
  end

  def accepted_reviewer_usernames
    Array.wrap(accepted_reviewers['reviewers'])
  end
end
