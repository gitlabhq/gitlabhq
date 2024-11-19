# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class BaseFormatter
      attr_reader :client, :formatter, :project, :raw_data, :source_user_mapper

      def initialize(project, raw_data, client = nil, source_user_mapper = nil)
        @project = project
        @raw_data = raw_data
        @client = client
        @formatter = Gitlab::ImportFormatter.new
        @source_user_mapper = source_user_mapper
      end

      def create!
        record = create_record
        push_placeholder_references(record)

        record
      end

      # rubocop: disable CodeReuse/ActiveRecord -- Existing legacy code
      def create_record
        association = project.public_send(project_association) # rubocop:disable GitlabSecurity/PublicSend

        association.find_or_create_by!(find_condition) do |record|
          record.attributes = attributes
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def push_placeholder_references(record, contributing_users: nil)
        contributing_users ||= contributing_user_formatters

        contributing_users.each do |user_reference_column, user_formatter|
          push_placeholder_reference(record, user_reference_column, user_formatter.source_user)
        end
      end

      def push_placeholder_reference(record, user_reference_column, source_user)
        return unless project.import_data.user_mapping_enabled?

        user_id = record[user_reference_column]

        return if user_id.nil? || source_user.nil?
        return if source_user.accepted_status? && user_id == source_user.reassign_to_user_id

        ::Import::PlaceholderReferences::PushService.from_record(
          import_source: imported_from,
          import_uid: project.import_state.id,
          record: record,
          source_user: source_user,
          user_reference_column: user_reference_column
        ).execute
      end

      def url
        raw_data[:url] || ''
      end

      def imported_from
        return ::Import::SOURCE_GITEA if project.gitea_import?
        return ::Import::SOURCE_GITHUB if project.github_import?

        ::Import::SOURCE_NONE
      end

      # A hash of user_reference_columns and its corresponding UserFormatter objects must be defined on each formatter
      # in order to save it using #create!
      def contributing_user_formatters
        raise NotImplementedError
      end
    end
  end
end
