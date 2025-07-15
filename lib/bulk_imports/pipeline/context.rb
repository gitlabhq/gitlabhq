# frozen_string_literal: true

module BulkImports
  module Pipeline
    class Context
      attr_accessor :extra

      attr_reader :tracker

      delegate :source_xid, :entity_type, to: :entity

      def initialize(tracker, extra = {})
        @tracker = tracker
        @extra = extra
      end

      def entity
        @entity ||= tracker.entity
      end

      def portable
        @portable ||= entity.group || entity.project
      end

      def import_export_config
        @import_export_config ||= ::BulkImports::FileTransfer.config_for(portable)
      end

      def group
        @group ||= entity.group
      end

      def bulk_import
        @bulk_import ||= entity.bulk_import
      end

      def bulk_import_id
        @bulk_import_id ||= bulk_import.id
      end

      def current_user
        @current_user ||= bulk_import.user
      end

      def configuration
        @configuration ||= bulk_import.configuration
      end

      def source_ghost_user_id
        @source_ghost_user_id ||= BulkImports::SourceInternalUserFinder.new(configuration).cached_ghost_user_id
      end

      def source_user_mapper
        @source_user_mapper ||= Gitlab::Import::SourceUserMapper.new(
          namespace: portable.root_ancestor,
          import_type: Import::SOURCE_DIRECT_TRANSFER,
          source_hostname: configuration.url
        )
      end

      def importer_user_mapping_enabled?
        Import::BulkImports::EphemeralData.new(bulk_import_id).importer_user_mapping_enabled?
      end

      def override_file_size_limit?
        Feature.enabled?(:import_admin_override_max_file_size, current_user) &&
          Feature.enabled?(:import_admin_override_max_file_size, portable.root_ancestor) &&
          current_user.can_admin_all_resources?
      end
    end
  end
end
