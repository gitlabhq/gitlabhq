# frozen_string_literal: true

module BulkImports
  module Exports
    class ProjectConfig < BaseConfig
      def base_export_path
        exportable.disk_path
      end

      def import_export_yaml
        ::Gitlab::ImportExport.config_file
      end
    end
  end
end
