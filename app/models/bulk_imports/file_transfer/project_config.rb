# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class ProjectConfig < BaseConfig
      def base_export_path
        portable.disk_path
      end

      def import_export_yaml
        ::Gitlab::ImportExport.config_file
      end

      def skipped_relations
        @skipped_relations ||= %w(project_members group_members)
      end
    end
  end
end
