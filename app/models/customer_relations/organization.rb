# frozen_string_literal: true

class CustomerRelations::Organization < ApplicationRecord
  include Gitlab::SQL::Pattern
  include Sortable
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
  validate :validate_crm_group

  scope :order_scope_asc, ->(field) { order(arel_table[field].asc.nulls_last) }
  scope :order_scope_desc, ->(field) { order(arel_table[field].desc.nulls_last) }

  # Searches for organizations with a matching name or description.
  #
  # This method uses ILIKE on PostgreSQL
  #
  # query - The search query as a String
  #
  # Returns an ActiveRecord::Relation.
  def self.search(query)
    fuzzy_search(query, [:name, :description], use_minimum_char_limit: false)
  end

  def self.search_by_state(state)
    where(state: state)
  end

  def self.sort_by_field(field, direction)
    if direction == :asc
      order_scope_asc(field)
    else
      order_scope_desc(field)
    end
  end

  def self.sort_by_name
    order(name: :asc)
  end

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
    connection.execute(sanitize_sql([update_query, { old_group_id: group.root_ancestor.id, new_group_id: group.id }]))

    dupes_query = <<~SQL
      DELETE FROM #{table_name} AS existing_organizations
      USING #{table_name} AS new_organizations
      WHERE existing_organizations.group_id = :new_group_id AND new_organizations.group_id = :old_group_id AND LOWER(new_organizations.name) = LOWER(existing_organizations.name)
    SQL
    connection.execute(sanitize_sql([dupes_query, { old_group_id: group.root_ancestor.id, new_group_id: group.id }]))

    where(group: group).update_all(group_id: group.root_ancestor.id)
  end

  def self.counts_by_state
    default_state_counts.merge(group(:state).count)
  end

  private

  def self.default_state_counts
    states.keys.index_with do |key|
      0
    end
  end

  def validate_crm_group
    return if group&.crm_group?

    self.errors.add(:base, _('organizations can only be added to root groups and groups configured as CRM targets'))
  end
end
