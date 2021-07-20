# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class GroupConfig < BaseConfig
      def base_export_path
        portable.full_path
      end

      def import_export_yaml
        ::Gitlab::ImportExport.group_config_file
      end

      def skipped_relations
        @skipped_relations ||= %w(members)
      end
    end
  end
end
