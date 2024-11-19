# frozen_string_literal: true

module Members
  class DeletionSchedule < ApplicationRecord
    self.table_name = 'members_deletion_schedules'

    belongs_to :namespace, optional: false
    belongs_to :user, optional: false
    belongs_to :scheduled_by, class_name: 'User', optional: false

    validates :user, uniqueness: { scope: :namespace_id, message: 'already scheduled for deletion' }
  end
end
