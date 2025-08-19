# frozen_string_literal: true

module Import
  module PlaceholderReferences
    module Pusher
      def push_reference(project, record, attribute, source_user_identifier)
        return unless allowed_to_push?(project, source_user_identifier)

        source_user = source_user_mapper(project).find_source_user(source_user_identifier)

        # Do not create a reference if the object is already associated with a real user.
        return if source_user_mapped_to_human?(record, attribute, source_user)

        ::Import::PlaceholderReferences::PushService.from_record(
          import_source: import_type,
          import_uid: project.import_state.id,
          record: record,
          source_user: source_user,
          user_reference_column: attribute
        ).execute
      end

      # This is used for records created using legacy_bulk_insert which can
      # return the ids of records created, but not the records themselves
      def push_references_by_ids(project, ids, model, attribute, source_user_identifier)
        return unless allowed_to_push?(project, source_user_identifier)

        ids.each do |id|
          source_user = source_user_mapper(project).find_source_user(source_user_identifier)

          next if source_user.nil?
          next if source_user.accepted_status?

          ::Import::PlaceholderReferences::PushService.new(
            import_source: import_type,
            import_uid: project.import_state.id,
            source_user_id: source_user.id,
            source_user_namespace_id: source_user.namespace_id,
            model: model,
            user_reference_column: attribute,
            numeric_key: id).execute
        end
      end

      # Pushes a placeholder reference using a composite key.
      # This is used when the record requires a composite key for the reference.
      def push_reference_with_composite_key(project, record, attribute, composite_key, source_user_identifier)
        return unless allowed_to_push?(project, source_user_identifier)

        source_user = source_user_mapper(project).find_source_user(source_user_identifier)

        # Do not create a reference if the object is already associated with a real user.
        return if source_user_mapped_to_human?(record, attribute, source_user)

        ::Import::PlaceholderReferences::PushService.new(
          import_source: import_type,
          import_uid: project.import_state.id,
          source_user_id: source_user.id,
          source_user_namespace_id: source_user.namespace_id,
          model: record.class,
          user_reference_column: attribute,
          composite_key: composite_key
        ).execute
      end

      def user_mapping_enabled?(project)
        project.import_data.user_mapping_enabled?
      end

      def map_to_personal_namespace_owner?(project)
        project.root_ancestor.user_namespace? &&
          project.import_data.user_mapping_to_personal_namespace_owner_enabled?
      end

      private

      def allowed_to_push?(project, source_user_identifier)
        source_user_identifier.present? && user_mapping_enabled?(project) && !map_to_personal_namespace_owner?(project)
      end

      def import_type
        @type ||= project.import_type.to_sym
      end

      def source_user_mapped_to_human?(record, attribute, source_user)
        source_user.nil? ||
          (source_user.accepted_status? && record[attribute] == source_user.reassign_to_user_id)
      end

      def source_user_mapper(project)
        @user_mapper ||= ::Gitlab::Import::SourceUserMapper.new(
          namespace: project.root_ancestor,
          source_hostname: project.safe_import_url,
          import_type: import_type
        )
      end
    end
  end
end
