# frozen_string_literal: true

class CustomerRelations::Organization < ApplicationRecord
  include StripAttribute

  self.table_name = "customer_relations_organizations"

  belongs_to :group, -> { where(type: Group.sti_name) }, foreign_key: 'group_id'

  strip_attributes! :name

  enum state: {
    inactive: 0,
    active: 1
  }

  validates :group, presence: true
  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false, scope: [:group_id] }
  validates :name, length: { maximum: 255 }
  validates :description, length: { maximum: 1024 }
  validate :validate_root_group

  def self.find_by_name(group_id, name)
    where(group: group_id)
    .where('LOWER(name) = LOWER(?)', name)
  end

  private

  def validate_root_group
    return if group&.root?

    self.errors.add(:base, _('organizations can only be added to root groups'))
  end
end
