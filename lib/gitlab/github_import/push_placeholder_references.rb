# frozen_string_literal: true

module Gitlab
  module GithubImport
    # Contains methods to push placeholder references for user contribution mapping
    module PushPlaceholderReferences
      # Pushes a placeholder reference using .from_record
      # Used when the record is available and the reference only requires a numeric key
      def push_with_record(record, attribute, source_user_identifier, user_mapper)
        return if source_user_identifier.nil?

        source_user = user_mapper.find_source_user(source_user_identifier)
        return if source_user.nil?
        return if source_user.accepted_status?

        ::Import::PlaceholderReferences::PushService.from_record(
          import_source: ::Import::SOURCE_GITHUB,
          import_uid: project.import_state.id,
          record: record,
          source_user: source_user,
          user_reference_column: attribute
        ).execute
      end

      # Pushes placeholder references for each Note record found via an id look-up using .new
      # This is used as Note records are created using legacy_bulk_insert which
      # can return the ids of records created, but not the records themselves
      def push_refs_with_ids(ids, model, source_user_identifier, user_mapper)
        return if source_user_identifier.nil?

        ids.each do |id|
          source_user = user_mapper.find_source_user(source_user_identifier)

          next if source_user.nil?
          next if source_user.accepted_status?

          ::Import::PlaceholderReferences::PushService.new(
            import_source: ::Import::SOURCE_GITHUB,
            import_uid: project.import_state.id,
            source_user_id: source_user.id,
            source_user_namespace_id: source_user.namespace_id,
            model: model,
            user_reference_column: :author_id,
            numeric_key: id).execute
        end
      end

      # Pushes a placeholder reference using a composite key.
      # This is used when the record requires a composite key for the reference.
      def push_with_composite_key(record, attribute, composite_key, source_user_identifier, user_mapper)
        return if source_user_identifier.nil?

        source_user = user_mapper.find_source_user(source_user_identifier)
        return if source_user.nil?
        return if source_user.accepted_status?

        ::Import::PlaceholderReferences::PushService.new(
          import_source: ::Import::SOURCE_GITHUB,
          import_uid: project.import_state.id,
          source_user_id: source_user.id,
          source_user_namespace_id: source_user.namespace_id,
          model: record.class,
          user_reference_column: attribute,
          composite_key: composite_key
        ).execute
      end
    end
  end
end
