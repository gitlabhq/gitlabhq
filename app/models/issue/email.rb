# frozen_string_literal: true

class Issue::Email < ApplicationRecord
  self.table_name = 'issue_emails'

  belongs_to :issue

  validates :email_message_id, uniqueness: true, presence: true, length: { maximum: 1000 }
  validates :issue, presence: true, uniqueness: true

  def work_item
    return unless issue_id.present?

    ::WorkItem.find(issue_id)
  end
end
