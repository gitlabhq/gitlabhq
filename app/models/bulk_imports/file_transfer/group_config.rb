# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class GroupConfig < BaseConfig
      DIRECT_TRANSFER_SKIPPED_RELATIONS = %w[members].freeze

      def import_export_yaml
        ::Gitlab::ImportExport.group_config_file
      end

      def skipped_relations
        return [] if offline?

        DIRECT_TRANSFER_SKIPPED_RELATIONS
      end
    end
  end
end
