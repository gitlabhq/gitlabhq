# frozen_string_literal: true

module BulkImports
  module Pipeline
    class Context
      attr_accessor :extra

      attr_reader :tracker

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

      def current_user
        @current_user ||= bulk_import.user
      end

      def configuration
        @configuration ||= bulk_import.configuration
      end
    end
  end
end
