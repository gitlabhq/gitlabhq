# frozen_string_literal: true

module Import
  module SourceUsers
    # This class generates CSV data for `Import::SourceUser` records associated
    # with a namespace. This spreadsheet is filled in and re-uploaded to
    # facilitate the user mapping flow.
    class GenerateCsvService
      HEADERS = [
        'Source host',
        'Import type',
        'Source user identifier',
        'Source user name',
        'Source username',
        'GitLab username',
        'GitLab public email'
      ].freeze

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
        CSV.generate do |csv|
          csv << HEADERS

          import_source_users.each_batch(of: 1000) do |batch|
            batch.each do |source_user|
              csv << [
                source_user.source_hostname,
                source_user.import_type,
                source_user.source_user_identifier,
                source_user.source_name,
                source_user.source_username,
                '',
                ''
              ]
            end
          end
        end
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
