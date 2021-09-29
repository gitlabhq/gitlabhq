# frozen_string_literal: true

class DependencyProxy::ImageTtlGroupPolicy < ApplicationRecord
  self.primary_key = :group_id

  belongs_to :group

  validates :group, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :ttl, numericality: { greater_than: 0 }, allow_nil: true

  scope :enabled, -> { where(enabled: true) }
end
