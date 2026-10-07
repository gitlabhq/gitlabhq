# frozen_string_literal: true

module Import
  module BulkImports
    class EphemeralData
      def initialize(bulk_import_id)
        @bulk_import_id = bulk_import_id
      end

      # request_channel records how a migration was started (api/ui/congregate),
      # captured at CreateService time and read later from workers when
      # start_project_import / start_group_import fire.
      def request_channel=(value)
        add('request_channel', value.to_s) if value.present?
      end

      def request_channel
        read('request_channel')
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
