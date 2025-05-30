# frozen_string_literal: true

module Namespaces
  class DeletionSchedule < ApplicationRecord
    self.table_name = 'namespace_deletion_schedules'

    belongs_to :namespace
    belongs_to :deleting_user, foreign_key: 'user_id', class_name: 'User', inverse_of: :namespace_deletion_schedules

    validates :marked_for_deletion_at, presence: true
  end
end
