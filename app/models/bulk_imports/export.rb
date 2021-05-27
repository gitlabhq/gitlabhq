# frozen_string_literal: true

module BulkImports
  class Export < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    STARTED = 0
    FINISHED = 1
    FAILED = -1

    self.table_name = 'bulk_import_exports'

    belongs_to :project, optional: true
    belongs_to :group, optional: true

    has_one :upload, class_name: 'BulkImports::ExportUpload'

    validates :project, presence: true, unless: :group
    validates :group, presence: true, unless: :project
    validates :relation, :status, presence: true

    validate :portable_relation?

    state_machine :status, initial: :started do
      state :started, value: STARTED
      state :finished, value: FINISHED
      state :failed, value: FAILED

      event :start do
        transition any => :started
      end

      event :finish do
        transition started: :finished
        transition failed: :failed
      end

      event :fail_op do
        transition any => :failed
      end
    end

    def portable_relation?
      return unless portable

      errors.add(:relation, 'Unsupported portable relation') unless config.portable_relations.include?(relation)
    end

    def portable
      strong_memoize(:portable) do
        project || group
      end
    end

    def relation_definition
      config.portable_tree[:include].find { |include| include[relation.to_sym] }
    end

    def config
      strong_memoize(:config) do
        FileTransfer.config_for(portable)
      end
    end
  end
end
