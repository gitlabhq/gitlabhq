# frozen_string_literal: true

module BulkImports
  module Pipeline
    class Context
      attr_reader :entity, :bulk_import
      attr_accessor :extra

      def initialize(entity, extra = {})
        @entity = entity
        @bulk_import = entity.bulk_import
        @extra = extra
      end

      def group
        entity.group
      end

      def current_user
        bulk_import.user
      end

      def configuration
        bulk_import.configuration
      end
    end
  end
end
