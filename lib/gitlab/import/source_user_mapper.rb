# frozen_string_literal: true

module Gitlab
  module Import
    class SourceUserMapper
      include Gitlab::ExclusiveLeaseHelpers

      def initialize(namespace:, import_type:, source_hostname:)
        @namespace = namespace
        @import_type = import_type
        @source_hostname = source_hostname
      end

      def find_or_create_internal_user(source_name:, source_username:, source_user_identifier:)
        @source_name = source_name
        @source_username = source_username
        @source_user_identifier = source_user_identifier

        internal_user = find_internal_user
        return internal_user if internal_user

        in_lock(lock_key(source_user_identifier), sleep_sec: 2.seconds) do |retried|
          if retried
            internal_user = find_internal_user
            next internal_user if internal_user
          end

          create_source_user_mapping
        end
      end

      private

      attr_reader :namespace, :import_type, :source_hostname, :source_name, :source_username, :source_user_identifier

      def find_internal_user
        source_user = ::Import::SourceUser.find_source_user(
          source_user_identifier: source_user_identifier,
          namespace: namespace,
          source_hostname: source_hostname,
          import_type: import_type
        )

        return unless source_user

        source_user.accepted_reassign_to_user || source_user.placeholder_user
      end

      def create_source_user_mapping
        ::Import::SourceUser.transaction do
          import_source_user = ::Import::SourceUser.new(
            namespace: namespace,
            import_type: import_type,
            source_username: source_username,
            source_name: source_name,
            source_user_identifier: source_user_identifier,
            source_hostname: source_hostname
          )

          internal_user = create_placeholder_user
          import_source_user.placeholder_user = internal_user

          import_source_user.save!
          import_source_user
        end
      end

      def create_placeholder_user
        # If limit is reached, get import user instead, but that's not implemented yet
        Gitlab::Import::PlaceholderUserCreator.new(
          import_type: import_type,
          source_hostname: source_hostname,
          source_name: source_name,
          source_username: source_username
        ).execute
      end

      def lock_key(source_user_identifier)
        "import:source_user_mapper:#{namespace.id}:#{import_type}:#{source_hostname}:#{source_user_identifier}"
      end
    end
  end
end
