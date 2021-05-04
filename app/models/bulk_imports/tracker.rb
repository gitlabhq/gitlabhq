# frozen_string_literal: true

class BulkImports::Tracker < ApplicationRecord
  self.table_name = 'bulk_import_trackers'

  alias_attribute :pipeline_name, :relation

  belongs_to :entity,
    class_name: 'BulkImports::Entity',
    foreign_key: :bulk_import_entity_id,
    optional: false

  validates :relation,
    presence: true,
    uniqueness: { scope: :bulk_import_entity_id }

  validates :next_page, presence: { if: :has_next_page? }

  validates :stage, presence: true

  DEFAULT_PAGE_SIZE = 500

  scope :next_pipeline_trackers_for, -> (entity_id) {
    entity_scope = where(bulk_import_entity_id: entity_id)
    next_stage_scope = entity_scope.with_status(:created).select('MIN(stage)')

    entity_scope.where(stage: next_stage_scope)
  }

  def self.stage_running?(entity_id, stage)
    where(stage: stage, bulk_import_entity_id: entity_id)
      .with_status(:created, :started)
      .exists?
  end

  def pipeline_class
    unless BulkImports::Stage.pipeline_exists?(pipeline_name)
      raise NameError, "'#{pipeline_name}' is not a valid BulkImport Pipeline"
    end

    pipeline_name.constantize
  end

  state_machine :status, initial: :created do
    state :created, value: 0
    state :started, value: 1
    state :finished, value: 2
    state :failed, value: -1
    state :skipped, value: -2

    event :start do
      transition created: :started
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
  end
end
