# frozen_string_literal: true

module Projects
  class DeletionSchedule < ApplicationRecord
    self.table_name = 'project_deletion_schedules'

    belongs_to :project
    belongs_to :deleting_user, foreign_key: 'user_id', class_name: 'User', inverse_of: :project_deletion_schedules

    validates :marked_for_deletion_at, presence: true
  end
end
