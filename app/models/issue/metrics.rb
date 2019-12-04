# frozen_string_literal: true

class Issue::Metrics < ApplicationRecord
  belongs_to :issue

  scope :for_issues, ->(issues) { where(issue: issues) }
  scope :with_first_mention_not_earlier_than, -> (timestamp) {
    where(first_mentioned_in_commit_at: nil)
      .or(where(arel_table['first_mentioned_in_commit_at'].gteq(timestamp)))
  }

  def record!
    if issue.milestone_id.present? && self.first_associated_with_milestone_at.blank?
      self.first_associated_with_milestone_at = Time.now
    end

    if issue_assigned_to_list_label? && self.first_added_to_board_at.blank?
      self.first_added_to_board_at = Time.now
    end

    self.save
  end

  private

  def issue_assigned_to_list_label?
    issue.labels.any? { |label| label.lists.present? }
  end
end
