# frozen_string_literal: true

class BulkImports::Tracker < ApplicationRecord
  include AfterCommitQueue

  self.table_name = 'bulk_import_trackers'

  alias_attribute :pipeline_name, :relation

  belongs_to :entity,
    class_name: 'BulkImports::Entity',
    inverse_of: :trackers,
    foreign_key: :bulk_import_entity_id,
    optional: false

  has_many :batches, class_name: 'BulkImports::BatchTracker', inverse_of: :tracker

  validates :relation,
    presence: true,
    uniqueness: { scope: :bulk_import_entity_id }

  validates :next_page, presence: { if: :has_next_page? }

  validates :stage, presence: true

  delegate :file_extraction_pipeline?, :abort_on_failure?, to: :pipeline_class

  DEFAULT_PAGE_SIZE = 500

  scope :next_pipeline_trackers_for, ->(entity_id) {
    entity_scope = where(bulk_import_entity_id: entity_id)
    next_stage_scope = entity_scope.with_status(:created).select('MIN(stage)')

    entity_scope.where(stage: next_stage_scope).with_status(:created)
  }

  scope :running_trackers, ->(entity_id) {
    where(bulk_import_entity_id: entity_id).with_status(:enqueued, :started)
  }

  def pipeline_class
    unless entity.pipeline_exists?(pipeline_name)
      raise BulkImports::Error, "'#{pipeline_name}' is not a valid BulkImport Pipeline"
    end

    pipeline_name.constantize
  end

  state_machine :status, initial: :created do
    state :created, value: 0
    state :started, value: 1
    state :finished, value: 2
    state :enqueued, value: 3
    state :timeout, value: 4
    state :failed, value: -1
    state :skipped, value: -2
    state :canceled, value: -3

    event :start do
      transition enqueued: :started
      # To avoid errors when re-starting a pipeline in case of network errors
      transition started: :started
    end

    event :retry do
      transition started: :enqueued
      # To avoid errors when retrying a pipeline in case of network errors
      transition enqueued: :enqueued
    end

    event :enqueue do
      transition created: :enqueued
    end

    event :finish do
      transition started: :finished
      transition failed: :failed
      transition skipped: :skipped
    end

    event :skip do
      transition any => :skipped
    end

    event :fail_op do
      transition any => :failed
    end

    event :cancel do
      transition any => :canceled
    end

    event :cleanup_stale do
      transition [:enqueued, :created, :started] => :timeout
    end

    after_transition any => [:finished, :failed] do |tracker|
      BulkImports::ObjectCounter.persist!(tracker)
    end

    after_transition any => [:canceled] do |tracker|
      tracker.run_after_commit do
        tracker.propagate_cancel
      end
    end
  end

  def checksums
    return unless file_extraction_pipeline?

    # Return cached counters until they expire
    { importing_relation => cached_checksums || persisted_checksums }
  end

  def checksums_empty?
    return true unless checksums

    sums = checksums[importing_relation]

    sums[:source] == 0 && sums[:fetched] == 0 && sums[:imported] == 0
  end

  def importing_relation
    pipeline_class.relation.to_sym
  end

  def propagate_cancel
    batches.each(&:cancel)
  end

  private

  def cached_checksums
    BulkImports::ObjectCounter.summary(self)
  end

  def persisted_checksums
    {
      source: source_objects_count,
      fetched: fetched_objects_count,
      imported: imported_objects_count
    }
  end
end
