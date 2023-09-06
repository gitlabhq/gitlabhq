# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class GroupConfig < BaseConfig
      SKIPPED_RELATIONS = %w[members].freeze

      def import_export_yaml
        ::Gitlab::ImportExport.group_config_file
      end

      def skipped_relations
        SKIPPED_RELATIONS
      end
    end
  end
end
