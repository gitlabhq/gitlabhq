# frozen_string_literal: true

class GroupCustomAttribute < ApplicationRecord
  belongs_to :group

  validates :group, :key, :value, presence: true
  validates :key, uniqueness: { scope: [:group_id] }
end
