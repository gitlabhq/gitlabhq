# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class ProjectConfig < BaseConfig
      SKIPPED_RELATIONS = %w[
        project_members
        group_members
      ].freeze

      LFS_OBJECTS_RELATION = 'lfs_objects'
      REPOSITORY_BUNDLE_RELATION = 'repository'
      DESIGN_BUNDLE_RELATION = 'design'
      COMMIT_NOTES_RELATION = 'commit_notes'

      def import_export_yaml
        ::Gitlab::ImportExport.config_file
      end

      def skipped_relations
        SKIPPED_RELATIONS
      end

      def file_relations
        [
          UPLOADS_RELATION,
          LFS_OBJECTS_RELATION,
          REPOSITORY_BUNDLE_RELATION,
          DESIGN_BUNDLE_RELATION
        ]
      end

      def export_service_for(relation)
        return ::Import::BulkImports::CommitNotesExportService if commit_notes_export_via_git?(relation)

        super
      end

      def batchable_relation?(relation)
        return true if commit_notes_export_via_git?(relation)

        super
      end

      def commit_notes_export_via_git?(relation)
        relation == COMMIT_NOTES_RELATION &&
          Feature.enabled?(:commit_notes_export_via_repo, portable.root_ancestor)
      end
    end
  end
end
