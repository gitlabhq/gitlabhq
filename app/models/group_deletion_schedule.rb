# frozen_string_literal: true

class GroupDeletionSchedule < ApplicationRecord
  belongs_to :group
  belongs_to :deleting_user, foreign_key: 'user_id', class_name: 'User'

  validates :marked_for_deletion_on, presence: true
end
