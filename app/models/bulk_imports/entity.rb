# frozen_string_literal: true

# The BulkImport::Entity represents a Group or Project to be imported during the
# bulk import process. An entity is nested under the parent group when it is not
# a top level group.
#
# A full bulk import entity structure might look like this, where the links are
# parents:
#
#          **Before Import**              **After Import**
#
#             GroupEntity                      Group
#              |      |                        |   |
#     GroupEntity   ProjectEntity          Group   Project
#          |                                 |
#    ProjectEntity                        Project
#
# The tree structure of the entities results in the same structure for imported
# Groups and Projects.
class BulkImports::Entity < ApplicationRecord
  self.table_name = 'bulk_import_entities'

  belongs_to :bulk_import, optional: false
  belongs_to :parent, class_name: 'BulkImports::Entity', optional: true

  belongs_to :project, optional: true
  belongs_to :group, foreign_key: :namespace_id, optional: true

  has_many :trackers,
    class_name: 'BulkImports::Tracker',
    foreign_key: :bulk_import_entity_id

  has_many :failures,
    class_name: 'BulkImports::Failure',
    inverse_of: :entity,
    foreign_key: :bulk_import_entity_id

  validates :project, absence: true, if: :group
  validates :group, absence: true, if: :project
  validates :source_type, :source_full_path, :destination_name, presence: true
  validates :destination_namespace, exclusion: [nil], if: :group
  validates :destination_namespace, presence: true, if: :project

  validate :validate_parent_is_a_group, if: :parent
  validate :validate_imported_entity_type

  validate :validate_destination_namespace_ascendency, if: :group_entity?

  enum source_type: { group_entity: 0, project_entity: 1 }

  scope :by_user_id, ->(user_id) { joins(:bulk_import).where(bulk_imports: { user_id: user_id }) }

  state_machine :status, initial: :created do
    state :created, value: 0
    state :started, value: 1
    state :finished, value: 2
    state :failed, value: -1

    event :start do
      transition created: :started
    end

    event :finish do
      transition started: :finished
      transition failed: :failed
    end

    event :fail_op do
      transition any => :failed
    end
  end

  def self.all_human_statuses
    state_machine.states.map(&:human_name)
  end

  def encoded_source_full_path
    ERB::Util.url_encode(source_full_path)
  end

  private

  def validate_parent_is_a_group
    unless parent.group_entity?
      errors.add(:parent, s_('BulkImport|must be a group'))
    end
  end

  def validate_imported_entity_type
    if group.present? && project_entity?
      errors.add(
        :group,
        s_('BulkImport|expected an associated Project but has an associated Group')
      )
    end

    if project.present? && group_entity?
      errors.add(
        :project,
        s_('BulkImport|expected an associated Group but has an associated Project')
      )
    end
  end

  def validate_destination_namespace_ascendency
    source = Group.find_by_full_path(source_full_path)

    return unless source

    if source.self_and_descendants.any? { |namespace| namespace.full_path == destination_namespace }
      errors.add(
        :base,
        s_('BulkImport|Import failed: Destination cannot be a subgroup of the source group. Change the destination and try again.')
      )
    end
  end
end
