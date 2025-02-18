# frozen_string_literal: true

module Import
  module SourceUsers
    class BulkReassignFromCsvService
      def initialize(current_user, namespace, upload)
        @upload = upload
        @current_user = current_user
        @namespace = namespace
        @reassignment_errors = {}

        raw_csv_data = upload.retrieve_uploader.file.read
        @csv_validator = ::Import::UserMapping::ReassignmentCsvValidator.new(raw_csv_data)
      end

      # @return [ServiceResponse]
      def async_execute
        return ServiceResponse.error(message: csv_validator.formatted_errors) unless csv_validator.valid?

        Import::UserMapping::AssignmentFromCsvWorker.perform_async(
          current_user.id,
          namespace.id,
          upload.id
        )

        ServiceResponse.success
      end

      # @return [ServiceResponse]
      def execute
        return ServiceResponse.error(message: :invalid_csv_format) unless csv_validator.valid?

        process_csv

        ServiceResponse.success(payload: {
          errors: reassignment_errors
        })
      end

      private

      attr_reader :upload, :current_user, :namespace, :csv_validator, :reassignment_errors

      def process_csv
        csv_data.each do |row_array|
          row = row_array.to_h

          attributes = attributes_for(row)
          result = process_line(attributes)

          @reassignment_errors[attributes[:source_user_identifier]] = result.message if result.error?
        end
      end

      def csv_data
        @csv_validator.csv_data
      end

      def attributes_for(row)
        {
          source_user_identifier: row[:source_user_identifier],
          username: row[:gitlab_username],
          email: row[:gitlab_public_email],
          host: row[:source_host],
          import_type: row[:import_type]
        }
      end

      def process_line(attributes)
        source_user = find_source_user(attributes)
        reassign_to_user = find_reassign_to_user(attributes)

        unless source_user && reassign_to_user
          return ServiceResponse.error(
            payload: attributes[:source_user_identifier],
            message: s_('UserMapping|No matching user for provided information.')
          )
        end

        ::Import::SourceUsers::ReassignService.new(
          source_user,
          reassign_to_user,
          current_user: current_user
        ).execute
      end

      def find_source_user(attributes)
        ::Import::SourceUser.find_source_user(
          source_user_identifier: attributes[:source_user_identifier],
          namespace: namespace,
          source_hostname: attributes[:host],
          import_type: attributes[:import_type]
        )
      end

      def find_reassign_to_user(attributes)
        search_criteria = attributes.slice(:email, :username).compact_blank

        if search_criteria[:email] && search_criteria[:username]
          user = User.by_username(search_criteria[:username])
          user_by_email(user, search_criteria[:email])
        elsif search_criteria[:email]
          user_by_email(User, search_criteria[:email])
        elsif search_criteria[:username]
          UserFinder.new(search_criteria[:username]).find_by_username
        end
      end

      def user_by_email(scope, email)
        user = scope.find_by_any_email(email, confirmed: true) if current_user_is_admin?
        user || scope.with_public_email(email).first
      end

      def current_user_is_admin?
        current_user.can_admin_all_resources?
      end
    end
  end
end
