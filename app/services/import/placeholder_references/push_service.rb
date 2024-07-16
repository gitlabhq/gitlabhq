# frozen_string_literal: true

module Import
  module PlaceholderReferences
    class PushService < BaseService
      class << self
        def from_record(import_source:, import_uid:, source_user:, record:, user_reference_column:, composite_key: nil)
          numeric_key = record.id if composite_key.nil? && record.id.is_a?(Integer)

          new(
            import_source: import_source,
            import_uid: import_uid,
            model: record.class,
            composite_key: composite_key,
            numeric_key: numeric_key,
            source_user_id: source_user.id,
            source_user_namespace_id: source_user.namespace_id,
            user_reference_column: user_reference_column
          )
        end
      end

      def initialize(import_source:, import_uid:, source_user_id:, source_user_namespace_id:, model:, user_reference_column:, numeric_key: nil, composite_key: nil) # rubocop:disable Layout/LineLength -- Its easier to read being on one line
        super(import_source: import_source, import_uid: import_uid)

        @reference = Import::SourceUserPlaceholderReference.new(
          model: model.name,
          source_user_id: source_user_id,
          namespace_id: source_user_namespace_id,
          user_reference_column: user_reference_column,
          numeric_key: numeric_key,
          composite_key: composite_key
        )
      end

      def execute
        return error(reference.errors.full_messages, :bad_request) unless reference.valid?

        serialized_reference = reference.to_serialized

        cache.set_add(cache_key, serialized_reference, timeout: cache_ttl)

        success(serialized_reference: serialized_reference)
      end

      private

      attr_reader :reference

      def cache_ttl
        Gitlab::Cache::Import::Caching::TIMEOUT
      end
    end
  end
end
