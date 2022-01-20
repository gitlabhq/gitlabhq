# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class ProjectConfig < BaseConfig
      SKIPPED_RELATIONS = %w(
        project_members
        group_members
      ).freeze

      LFS_OBJECTS_RELATION = 'lfs_objects'

      def import_export_yaml
        ::Gitlab::ImportExport.config_file
      end

      def skipped_relations
        SKIPPED_RELATIONS
      end

      def file_relations
        [UPLOADS_RELATION, LFS_OBJECTS_RELATION]
      end
    end
  end
end
