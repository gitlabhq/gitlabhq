# frozen_string_literal: true

# This class is used to store ephemeral data during a BulkImport.
module Import
  module BulkImports
    class EphemeralData
      def initialize(bulk_import_id)
        @bulk_import_id = bulk_import_id
      end

      def enable_importer_user_mapping
        add('importer_user_mapping', 'enabled')
      end

      def importer_user_mapping_enabled?
        read('importer_user_mapping') == 'enabled'
      end

      private

      attr_reader :bulk_import_id

      def add(field, value)
        Gitlab::Cache::Import::Caching.hash_add(cache_key, field, value)
      end

      def read(field)
        Gitlab::Cache::Import::Caching.value_from_hash(cache_key, field)
      end

      def cache_key
        "bulk_import_ephemeral_data_#{bulk_import_id}"
      end
    end
  end
end
