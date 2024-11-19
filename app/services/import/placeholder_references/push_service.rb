# frozen_string_literal: true

module Import
  module PlaceholderReferences
    InvalidReferenceError = Class.new(StandardError)

    class PushService < BaseService
      class << self
        def from_record(import_source:, import_uid:, source_user:, record:, user_reference_column:)
          if record.is_a?(IssueAssignee)
            composite_key = { 'issue_id' => record.issue_id, 'user_id' => record.user_id }
          elsif record.respond_to?(:id) && record.id.is_a?(Integer)
            numeric_key = record.id
          end

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

      def initialize(
        import_source:, import_uid:, source_user_id:, source_user_namespace_id:, model:,
        user_reference_column:, numeric_key: nil, composite_key: nil)
        super(import_source: import_source, import_uid: import_uid)

        @reference = Import::SourceUserPlaceholderReference.new(
          model: model.name,
          source_user_id: source_user_id,
          namespace_id: source_user_namespace_id,
          user_reference_column: user_reference_column,
          numeric_key: numeric_key,
          composite_key: composite_key,
          alias_version: PlaceholderReferences::AliasResolver.version_for_model(model.name)
        )
      end

      def execute
        if reference.invalid?
          track_error(reference)

          return error(reference.errors.full_messages, :bad_request)
        end

        serialized_reference = reference.to_serialized

        store.add(serialized_reference)

        success(serialized_reference: serialized_reference)
      end

      private

      attr_reader :reference

      def track_error(reference)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          InvalidReferenceError.new('Invalid placeholder user reference'),
          model: reference.model,
          errors: reference.errors.full_messages.join(', ')
        )
      end
    end
  end
end
