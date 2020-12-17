# frozen_string_literal: true

class MergeRequest::Metrics < ApplicationRecord
  belongs_to :merge_request, inverse_of: :metrics
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :pipeline_id
  belongs_to :latest_closed_by, class_name: 'User'
  belongs_to :merged_by, class_name: 'User'

  before_save :ensure_target_project_id

  scope :merged_after, ->(date) { where(arel_table[:merged_at].gteq(date)) }
  scope :merged_before, ->(date) { where(arel_table[:merged_at].lteq(date)) }
  scope :with_valid_time_to_merge, -> { where(arel_table[:merged_at].gt(arel_table[:created_at])) }

  def self.time_to_merge_expression
    Arel.sql('EXTRACT(epoch FROM SUM(AGE(merge_request_metrics.merged_at, merge_request_metrics.created_at)))')
  end

  private

  def ensure_target_project_id
    self.target_project_id ||= merge_request.target_project_id
  end
end

MergeRequest::Metrics.prepend_if_ee('EE::MergeRequest::Metrics')
