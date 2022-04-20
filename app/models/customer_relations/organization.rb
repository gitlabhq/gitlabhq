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

  def self.move_to_root_group(group)
    update_query = <<~SQL
      UPDATE #{CustomerRelations::Contact.table_name}
      SET organization_id = new_organizations.id
      FROM #{table_name} AS existing_organizations
      JOIN #{table_name} AS new_organizations ON new_organizations.group_id = :old_group_id AND LOWER(new_organizations.name) = LOWER(existing_organizations.name)
      WHERE existing_organizations.group_id = :new_group_id AND organization_id = existing_organizations.id
    SQL
    connection.execute(sanitize_sql([
      update_query,
      old_group_id: group.root_ancestor.id,
      new_group_id: group.id
      ]))

    dupes_query = <<~SQL
      DELETE FROM #{table_name} AS existing_organizations
      USING #{table_name} AS new_organizations
      WHERE existing_organizations.group_id = :new_group_id AND new_organizations.group_id = :old_group_id AND LOWER(new_organizations.name) = LOWER(existing_organizations.name)
    SQL
    connection.execute(sanitize_sql([
      dupes_query,
      old_group_id: group.root_ancestor.id,
      new_group_id: group.id
      ]))

    where(group: group).update_all(group_id: group.root_ancestor.id)
  end

  private

  def validate_root_group
    return if group&.root?

    self.errors.add(:base, _('organizations can only be added to root groups'))
  end
end
