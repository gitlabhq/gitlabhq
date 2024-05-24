# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationExport < ApplicationRecord
      DESIGN_REPOSITORY_RELATION = 'design_repository'
      LFS_OBJECTS_RELATION = 'lfs_objects'
      REPOSITORY_RELATION = 'repository'
      ROOT_RELATION = 'project'
      SNIPPETS_REPOSITORY_RELATION = 'snippets_repository'
      UPLOADS_RELATION = 'uploads'
      WIKI_REPOSITORY_RELATION = 'wiki_repository'

      EXTRA_RELATION_LIST = [
        DESIGN_REPOSITORY_RELATION, LFS_OBJECTS_RELATION, REPOSITORY_RELATION, ROOT_RELATION,
        SNIPPETS_REPOSITORY_RELATION, UPLOADS_RELATION, WIKI_REPOSITORY_RELATION
      ].freeze
      private_constant :EXTRA_RELATION_LIST

      self.table_name = 'project_relation_exports'

      belongs_to :project_export_job

      has_one :upload,
        class_name: 'Projects::ImportExport::RelationExportUpload',
        foreign_key: :project_relation_export_id,
        inverse_of: :relation_export

      validates :export_error, length: { maximum: 300 }
      validates :jid, length: { maximum: 255 }
      validates :project_export_job, presence: true
      validates :relation, presence: true, length: { maximum: 255 }, uniqueness: { scope: :project_export_job_id }
      validates :status, numericality: { only_integer: true }, presence: true

      scope :by_relation, ->(relation) { where(relation: relation) }

      STATUS = {
        queued: 0,
        started: 1,
        finished: 2,
        failed: 3
      }.freeze

      state_machine :status, initial: :queued do
        state :queued, value: STATUS[:queued]
        state :started, value: STATUS[:started]
        state :finished, value: STATUS[:finished]
        state :failed, value: STATUS[:failed]

        event :start do
          transition queued: :started
        end

        event :retry do
          transition started: :queued
        end

        event :finish do
          transition started: :finished
        end

        event :fail_op do
          transition [:queued, :started, :failed] => :failed
        end
      end

      def self.relation_names_list
        project_tree_relation_names = ::Gitlab::ImportExport::Reader.new(shared: nil).project_relation_names.map(&:to_s)

        project_tree_relation_names + EXTRA_RELATION_LIST
      end

      def mark_as_failed(export_error)
        sanitized_error = Gitlab::UrlSanitizer.sanitize(export_error)

        fail_op

        update_column(:export_error, sanitized_error)
      end
    end
  end
end
