# frozen_string_literal: true

class CustomerRelations::Organization < ApplicationRecord
  self.table_name = "customer_relations_organizations"

  belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'group_id'

  before_validation :strip_whitespace!

  enum state: {
    inactive: 0,
    active: 1
  }

  validates :group, presence: true
  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false, scope: [:group_id] }
  validates :name, length: { maximum: 255 }
  validates :description, length: { maximum: 1024 }

  def self.find_by_name(group_id, name)
    where(group: group_id)
    .where('LOWER(name) = LOWER(?)', name)
  end

  private

  def strip_whitespace!
    name&.strip!
  end
end
