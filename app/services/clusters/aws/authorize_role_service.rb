# frozen_string_literal: true

module Clusters
  module Aws
    class AuthorizeRoleService
      attr_reader :user

      Response = Struct.new(:status, :body)

      ERRORS = [
        ActiveRecord::RecordInvalid,
        ActiveRecord::RecordNotFound,
        Clusters::Aws::FetchCredentialsService::MissingRoleError,
        ::Aws::Errors::MissingCredentialsError,
        ::Aws::STS::Errors::ServiceError
      ].freeze

      def initialize(user, params:)
        @user = user
        @role_arn = params[:role_arn]
        @region = params[:region]
      end

      def execute
        ensure_role_exists!
        update_role_arn!

        Response.new(:ok, credentials)
      rescue *ERRORS => e
        Gitlab::ErrorTracking.track_exception(e)

        Response.new(:unprocessable_entity, response_details(e))
      end

      private

      attr_reader :role, :role_arn, :region

      def ensure_role_exists!
        @role = ::Aws::Role.find_by_user_id!(user.id)
      end

      def update_role_arn!
        role.update!(role_arn: role_arn, region: region)
      end

      def credentials
        Clusters::Aws::FetchCredentialsService.new(role).execute
      end

      def response_details(exception)
        message =
          case exception
          when ::Aws::STS::Errors::AccessDenied
            _("Access denied: %{error}") % { error: exception.message }
          when ::Aws::STS::Errors::ServiceError
            _("AWS service error: %{error}") % { error: exception.message }
          when ActiveRecord::RecordNotFound
            _("Error: Unable to find AWS role for current user")
          when ActiveRecord::RecordInvalid
            exception.message
          when Clusters::Aws::FetchCredentialsService::MissingRoleError
            _("Error: No AWS provision role found for user")
          when ::Aws::Errors::MissingCredentialsError
            _("Error: No AWS credentials were supplied")
          else
            _('An error occurred while authorizing your role')
          end

        { message: message }.compact
      end
    end
  end
end
