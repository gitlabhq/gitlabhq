# frozen_string_literal: true

class MergeRequest::Metrics < ApplicationRecord
  belongs_to :merge_request, inverse_of: :metrics
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :pipeline_id
  belongs_to :latest_closed_by, class_name: 'User'
  belongs_to :merged_by, class_name: 'User'

  before_save :ensure_target_project_id

  private

  def ensure_target_project_id
    self.target_project_id ||= merge_request.target_project_id
  end
end

MergeRequest::Metrics.prepend_if_ee('EE::MergeRequest::Metrics')
