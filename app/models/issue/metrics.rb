# frozen_string_literal: true

class Issue::Metrics < ApplicationRecord
  belongs_to :issue

  scope :for_issues, ->(issues) { where(issue: issues) }
  scope :with_first_mention_not_earlier_than, ->(timestamp) {
    where(first_mentioned_in_commit_at: nil)
      .or(where(arel_table['first_mentioned_in_commit_at'].gteq(timestamp)))
  }

  class << self
    def record!(issue)
      now = connection.quote(Time.current)
      first_associated_with_milestone_at = issue.milestone_id.present? ? now : 'NULL'
      first_added_to_board_at = issue_assigned_to_list_label?(issue) ? now : 'NULL'

      sql = <<~SQL
        INSERT INTO #{self.table_name} (issue_id, first_associated_with_milestone_at, first_added_to_board_at, created_at, updated_at)
        VALUES (#{issue.id}, #{first_associated_with_milestone_at}, #{first_added_to_board_at}, NOW(), NOW())
        ON CONFLICT (issue_id)
        DO UPDATE SET
          first_associated_with_milestone_at = LEAST(#{self.table_name}.first_associated_with_milestone_at, EXCLUDED.first_associated_with_milestone_at),
          first_added_to_board_at = LEAST(#{self.table_name}.first_added_to_board_at, EXCLUDED.first_added_to_board_at),
          updated_at = NOW()
        RETURNING id
      SQL

      connection.execute(sql)
    end

    private

    def issue_assigned_to_list_label?(issue)
      issue.labels.joins(:lists).exists?
    end
  end
end
