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
  include AfterCommitQueue

  self.table_name = 'bulk_import_entities'

  FailedError = Class.new(StandardError)

  belongs_to :bulk_import, optional: false
  belongs_to :parent, class_name: 'BulkImports::Entity', optional: true

  belongs_to :project, optional: true
  belongs_to :organization, class_name: 'Organizations::Organization', optional: true
  belongs_to :group, foreign_key: :namespace_id, optional: true, inverse_of: :bulk_import_entities

  has_many :trackers,
    class_name: 'BulkImports::Tracker',
    inverse_of: :entity,
    foreign_key: :bulk_import_entity_id

  has_many :failures,
    class_name: 'BulkImports::Failure',
    inverse_of: :entity,
    foreign_key: :bulk_import_entity_id

  validates :project, absence: true, if: :group
  validates :group, absence: true, if: :project
  validates :source_type, presence: true
  validates :source_full_path, presence: true
  validates :destination_name, presence: true, if: -> { group || project }
  validates :destination_namespace, exclusion: [nil], if: :group
  validates :destination_namespace, presence: true, if: :project?

  # TODO: Remove `on: :create` once the post migration SetOrganizationIdForBulkImportEntities has run
  validate :validate_only_one_sharding_key_present, on: :create
  validate :validate_parent_is_a_group, if: :parent
  validate :validate_imported_entity_type
  validate :validate_destination_namespace_ascendency, if: :group_entity?
  validate :validate_source_full_path_format

  enum source_type: { group_entity: 0, project_entity: 1 }

  scope :by_user_id, ->(user_id) { joins(:bulk_import).where(bulk_imports: { user_id: user_id }) }
  scope :stale, -> { where('updated_at < ?', 24.hours.ago).where(status: [0, 1]) }
  scope :by_bulk_import_id, ->(bulk_import_id) { where(bulk_import_id: bulk_import_id) }
  scope :order_by_created_at, ->(direction) { order(created_at: direction) }
  scope :order_by_updated_at_and_id, ->(direction) { order(updated_at: direction, id: :asc) }
  scope :with_trackers, -> { includes(:trackers) }

  alias_attribute :destination_slug, :destination_name

  delegate :default_project_visibility, :default_group_visibility,
    to: :'Gitlab::CurrentSettings.current_application_settings'

  state_machine :status, initial: :created do
    state :created, value: 0
    state :started, value: 1
    state :finished, value: 2
    state :timeout, value: 3
    state :failed, value: -1
    state :canceled, value: -2

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

    event :cleanup_stale do
      transition created: :timeout
      transition started: :timeout
    end

    event :cancel do
      transition any => :canceled
    end

    # rubocop:disable Style/SymbolProc
    after_transition any => [:finished, :failed, :timeout] do |entity|
      entity.update_has_failures
    end
    # rubocop:enable Style/SymbolProc

    after_transition any => [:canceled] do |entity|
      entity.run_after_commit do
        entity.propagate_cancel
      end
    end
  end

  def self.all_human_statuses
    state_machine.states.map(&:human_name)
  end

  def encoded_source_full_path
    ERB::Util.url_encode(source_full_path)
  end

  def pipelines
    @pipelines ||= case source_type
                   when 'group_entity'
                     BulkImports::Groups::Stage.new(self).pipelines
                   when 'project_entity'
                     BulkImports::Projects::Stage.new(self).pipelines
                   end
  end

  def pipeline_exists?(name)
    pipelines.any? { _1[:pipeline].to_s == name.to_s }
  end

  def entity_type
    source_type.gsub('_entity', '')
  end

  def pluralized_name
    entity_type.pluralize
  end

  def portable_class
    entity_type.classify.constantize
  end

  def base_resource_url_path
    "/#{pluralized_name}/#{encoded_source_full_path}"
  end

  def base_xid_resource_url_path
    "/#{pluralized_name}/#{source_xid}"
  end

  def base_resource_path
    if source_xid.present?
      base_xid_resource_url_path
    else
      base_resource_url_path
    end
  end

  def export_relations_url_path_base
    File.join(base_resource_path, 'export_relations')
  end

  def export_relations_url_path
    if bulk_import.supports_batched_export?
      Gitlab::Utils.add_url_parameters(export_relations_url_path_base, batched: true)
    else
      export_relations_url_path_base
    end
  end

  def relation_download_url_path(relation, batch_number = nil)
    url = File.join(export_relations_url_path_base, 'download')
    params = { relation: relation }

    params.merge!(batched: true, batch_number: batch_number) if batch_number && bulk_import.supports_batched_export?

    Gitlab::Utils.add_url_parameters(url, params)
  end

  def wikis_url_path
    "#{base_resource_path}/wikis"
  end

  def project?
    source_type == 'project_entity'
  end

  def group?
    source_type == 'group_entity'
  end

  def update_service
    "::#{pluralized_name.capitalize}::UpdateService".constantize
  end

  def full_path
    project? ? project&.full_path : group&.full_path
  end

  def full_path_with_fallback
    full_path || Gitlab::Utils.append_path(destination_namespace, destination_slug)
  end

  def default_visibility_level
    return default_group_visibility if group?

    default_project_visibility
  end

  def update_has_failures
    return if has_failures
    return unless failures.any?

    update!(has_failures: true)
    bulk_import.update!(has_failures: true)
  end

  def source_version
    @source_version ||= bulk_import.source_version_info
  end

  def checksums
    trackers.each_with_object({}) do |tracker, checksums|
      next unless tracker.file_extraction_pipeline?
      next if tracker.skipped?
      next if tracker.checksums_empty?

      checksums.merge!(tracker.checksums)
    end
  end

  def propagate_cancel
    trackers.each(&:cancel)
  end

  private

  def validate_only_one_sharding_key_present
    return if [group, project, organization].compact.one?

    errors.add(:base, s_("BulkImport|Import failed: Must have exactly one of organization, group or project."))
  end

  def validate_parent_is_a_group
    errors.add(:parent, s_('BulkImport|must be a group')) unless parent.group_entity?
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

  def validate_source_full_path_format
    validator = group? ? NamespacePathValidator : ProjectPathValidator

    return if validator.valid_path?(source_full_path)

    errors.add(
      :source_full_path,
      s_('BulkImport|must have a relative path structure with no HTTP ' \
         'protocol characters, or leading or trailing forward slashes. Path segments must not start or ' \
         'end with a special character, and must not contain consecutive special characters')
    )
  end
end
