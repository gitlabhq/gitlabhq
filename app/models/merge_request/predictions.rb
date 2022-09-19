# frozen_string_literal: true

class MergeRequest::Predictions < ApplicationRecord  # rubocop:disable Style/ClassAndModuleChildren
  belongs_to :merge_request, inverse_of: :predictions

  validates :suggested_reviewers, json_schema: { filename: 'merge_request_predictions_suggested_reviewers' }
end
