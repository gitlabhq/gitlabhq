# frozen_string_literal: true

module AlertManagement
  class AlertAssignee < ApplicationRecord
    belongs_to :alert, inverse_of: :alert_assignees
    belongs_to :assignee, class_name: 'User', foreign_key: :user_id, inverse_of: :alert_assignees

    validates :alert, presence: true
    validates :assignee, presence: true, uniqueness: { scope: :alert_id }
  end
end
