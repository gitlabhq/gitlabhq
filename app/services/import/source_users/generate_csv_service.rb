# frozen_string_literal: true

module Import
  module SourceUsers
    # This class generates CSV data for `Import::SourceUser` records associated
    # with a namespace. This spreadsheet is filled in and re-uploaded to
    # facilitate the user mapping flow.
    class GenerateCsvService
      # This is just to prevent any potential abuse. A test file with 20k rows
      # comes in at 2.3MB. A 10MB file would be several tens of thousands,
      # whereas we would rarely expect to exceed 10k rows.
      FILESIZE_LIMIT = 10.megabytes

      COLUMN_MAPPING = {
        'Source host' => 'source_hostname',
        'Import type' => 'import_type',
        'Source user identifier' => 'source_user_identifier',
        'Source user name' => 'source_name',
        'Source username' => 'source_username',
        'GitLab username' => ->(_) { '' },
        'GitLab public email' => ->(_) { '' }
      }.freeze

      # @param namespace [Namespace, Group] The namespace where the import source users are associated
      # @param current_user [User] The user performing the CSV export
      def initialize(namespace, current_user:)
        @namespace = namespace
        @current_user = current_user
      end

      def execute
        # We use :owner_access here because it's shared between GroupPolicy and
        # NamespacePolicy.
        return error_invalid_permissions unless current_user.can?(:owner_access, namespace)

        ServiceResponse.success(payload: csv_data)
      end

      private

      attr_reader :namespace, :current_user

      def csv_data
        CsvBuilder.new(import_source_users, COLUMN_MAPPING, replace_newlines: true).render(FILESIZE_LIMIT)
      end

      def import_source_users
        statuses = Import::SourceUser::STATUSES.slice(*Import::SourceUser::REASSIGNABLE_STATUSES).values
        namespace.import_source_users.by_statuses(statuses)
      end

      def error_invalid_permissions
        ServiceResponse.error(
          message: s_('Import|You do not have permission to view import source users for this namespace'),
          reason: :forbidden
        )
      end
    end
  end
end
