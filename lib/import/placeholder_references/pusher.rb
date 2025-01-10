# frozen_string_literal: true

module Import
  module PlaceholderReferences
    module Pusher
      def push_reference(project, record, attribute, source_user_identifier)
        return unless user_mapping_enabled?(project)
        return if source_user_identifier.nil?

        source_user = source_user_mapper(project).find_source_user(source_user_identifier)

        # Do not create a reference if the object is already associated
        # with a real user.
        return if source_user_mapped_to_human?(record, attribute, source_user)

        ::Import::PlaceholderReferences::PushService.from_record(
          import_source: ::Import::SOURCE_BITBUCKET_SERVER,
          import_uid: project.import_state.id,
          record: record,
          source_user: source_user,
          user_reference_column: attribute
        ).execute
      end

      def source_user_mapped_to_human?(record, attribute, source_user)
        source_user.nil? ||
          (source_user.accepted_status? && record[attribute] == source_user.reassign_to_user_id)
      end

      def source_user_mapper(project)
        @user_mapper ||= ::Gitlab::Import::SourceUserMapper.new(
          namespace: project.root_ancestor,
          source_hostname: project.import_url,
          import_type: ::Import::SOURCE_BITBUCKET_SERVER
        )
      end

      def user_mapping_enabled?(project)
        !!project.import_data.user_mapping_enabled?
      end
    end
  end
end
