# frozen_string_literal: true

module Organizations
  module OrganizationUsers
    class CreateService
      include BaseServiceUtility
      include Gitlab::Utils::StrongMemoize

      def initialize(organization, current_user:, params: {})
        @organization = organization
        @current_user = current_user
        @params = params.dup
      end

      def execute
        return error_no_permissions unless allowed?
        return error_user_not_found if user_to_add.nil?
        return error_already_member if already_member?
        return error_home_organization_isolated if home_organization_isolated?

        organization_user = create_organization_user!(user_to_add)

        ServiceResponse.success(payload: { organization_user: organization_user })
      rescue ActiveRecord::RecordInvalid => e
        error_creating(e.record)
      end

      private

      attr_reader :organization, :current_user, :params

      def user_to_add
        user_by_username || user_by_email
      end
      strong_memoize_attr :user_to_add

      def already_member?
        organization.users.id_in(user_to_add).exists?
      end

      def home_organization_isolated?
        user_to_add.organization&.isolated?
      end

      def user_by_username
        username = params[:username]
        return if username.blank?

        ::User.by_username(username).first
      end

      def user_by_email
        email = params[:email]
        return if email.blank?

        ::User.by_any_email(email, confirmed: true).first
      end

      def create_organization_user!(user)
        organization.organization_users.create!(user: user, access_level: params[:user_type])
      end

      def allowed?
        current_user&.can?(:create_organization_user, organization.organization_users.new)
      end

      def error_no_permissions
        ServiceResponse.error(message: [_('You have insufficient permissions to create an organization user')])
      end

      def error_user_not_found
        ServiceResponse.error(message: [_('The user could not be found')])
      end

      def error_already_member
        ServiceResponse.error(message: [_('The user is already a member of the organization')])
      end

      def error_home_organization_isolated
        ServiceResponse.error(message: [_('The user cannot be added because their home organization is isolated')])
      end

      # The unsaved record is left out of the payload: it has no ID, so callers such as GraphQL
      # cannot build a Global ID for it.
      def error_creating(organization_user)
        message = organization_user.errors.full_messages
        message = _('Failed to create the organization user') if message.empty?

        ServiceResponse.error(message: Array(message))
      end
    end
  end
end
