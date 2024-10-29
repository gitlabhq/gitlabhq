# frozen_string_literal: true

# The BulkImport model links all models required for a bulk import of groups and
# projects to a GitLab instance. It associates the import with the responsible
# user.
class BulkImport < ApplicationRecord
  include AfterCommitQueue

  MIN_MAJOR_VERSION = 14
  MIN_MINOR_VERSION_FOR_PROJECT = 4

  belongs_to :user, optional: false

  has_one :configuration, class_name: 'BulkImports::Configuration'
  has_many :entities, class_name: 'BulkImports::Entity'

  validates :source_type, :status, presence: true

  enum source_type: { gitlab: 0 }

  scope :stale, -> { where('updated_at < ?', 24.hours.ago).where(status: [0, 1]) }
  scope :order_by_updated_at_and_id, ->(direction) { order(updated_at: direction, id: :asc) }
  scope :order_by_created_at, ->(direction) { order(created_at: direction) }
  scope :with_configuration, -> { includes(:configuration) }

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
    end

    event :cleanup_stale do
      transition created: :timeout
      transition started: :timeout
    end

    event :fail_op do
      transition any => :failed
    end

    event :cancel do
      transition any => :canceled
    end

    after_transition any => [:finished, :failed, :timeout] do |bulk_import|
      bulk_import.update_has_failures
      bulk_import.send_completion_notification
    end
    after_transition any => [:canceled] do |bulk_import|
      bulk_import.run_after_commit do
        bulk_import.propagate_cancel
      end
    end
  end

  def source_version_info
    Gitlab::VersionInfo.parse(source_version)
  end

  def self.min_gl_version_for_project_migration
    Gitlab::VersionInfo.new(MIN_MAJOR_VERSION, MIN_MINOR_VERSION_FOR_PROJECT)
  end

  def self.min_gl_version_for_migration_in_batches
    Gitlab::VersionInfo.new(16, 2)
  end

  def self.all_human_statuses
    state_machine.states.map(&:human_name)
  end

  def update_has_failures
    return if has_failures
    return unless entities.any?(&:has_failures)

    update!(has_failures: true)
  end

  def propagate_cancel
    return unless entities.any?

    entities.each(&:cancel)
  end

  def supports_batched_export?
    source_version_info >= self.class.min_gl_version_for_migration_in_batches
  end

  def completed?
    finished? || failed? || timeout? || canceled?
  end

  def send_completion_notification
    run_after_commit do
      Notify.bulk_import_complete(user.id, id).deliver_later
    end
  end

  def destination_group_roots
    entities.where(parent: nil).filter_map do |entity|
      entity.group || entity.project
    end.map(&:root_ancestor).uniq
  end

  def namespaces_with_unassigned_placeholders
    namespaces = destination_group_roots
    namespace_ids = namespaces.collect(&:id)

    reassignable_statuses = Import::SourceUser::STATUSES.slice(*Import::SourceUser::REASSIGNABLE_STATUSES).values
    source_users = Import::SourceUser.for_namespace(namespace_ids).by_statuses(reassignable_statuses)
    valid_namespace_ids = source_users.collect(&:namespace_id).uniq

    namespaces.select { |namespace| valid_namespace_ids.include?(namespace.id) }
  end

  def source_url
    configuration&.url
  end
end
