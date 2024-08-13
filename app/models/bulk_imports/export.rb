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
    belongs_to :user, optional: true

    has_one :upload, class_name: 'BulkImports::ExportUpload'
    has_many :batches, class_name: 'BulkImports::ExportBatch'

    validates :project, presence: true, unless: :group
    validates :group, presence: true, unless: :project
    validates :relation, :status, presence: true

    validate :portable_relation?

    scope :for_status, ->(status) { where(status: status) }
    scope :for_user, ->(user) { where(user: user) }
    scope :for_user_and_relation, ->(user, relation) { where(user: user, relation: relation) }

    state_machine :status, initial: :started do
      state :started, value: STARTED
      state :finished, value: FINISHED
      state :failed, value: FAILED

      event :start do
        transition any => :started
      end

      event :finish do
        transition any => :finished
      end

      event :fail_op do
        transition any => :failed
      end

      after_transition any => :finished do |export|
        if export.config.user_contributions_relation?(export.relation)
          UserContributionsExportMapper.new(export.portable).clear_cache
        end
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
      config.relation_definition_for(relation)
    end

    def config
      strong_memoize(:config) do
        FileTransfer.config_for(portable)
      end
    end

    def remove_existing_upload!
      return unless upload&.export_file&.file

      upload.remove_export_file!
      upload.save!
    end

    def relation_has_user_contributions?
      config.relation_has_user_contributions?(relation)
    end
  end
end
