# frozen_string_literal: true

class BulkImports::Entity < ApplicationRecord
  self.table_name = 'bulk_import_entities'

  belongs_to :bulk_import, optional: false
  belongs_to :parent, class_name: 'BulkImports::Entity', optional: true

  belongs_to :project, optional: true
  belongs_to :group, foreign_key: :namespace_id, optional: true

  validates :project, absence: true, if: :group
  validates :group, absence: true, if: :project
  validates :source_type, :source_full_path, :destination_name,
            :destination_namespace, presence: true

  validate :validate_parent_is_a_group, if: :parent
  validate :validate_imported_entity_type

  enum source_type: { group_entity: 0, project_entity: 1 }

  state_machine :status, initial: :created do
    state :created, value: 0
  end

  private

  def validate_parent_is_a_group
    unless parent.group_entity?
      errors.add(:parent, s_('BulkImport|must be a group'))
    end
  end

  def validate_imported_entity_type
    if group.present? && project_entity?
      errors.add(:group, s_('BulkImport|expected an associated Project but has an associated Group'))
    end

    if project.present? && group_entity?
      errors.add(:project, s_('BulkImport|expected an associated Group but has an associated Project'))
    end
  end
end
