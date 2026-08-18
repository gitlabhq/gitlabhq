# frozen_string_literal: true

module Organizations
  # Creates an unconfirmed organization for a TLG and transfer the TLG into it.
  class CreateFromGroupService
    include Gitlab::Allowable

    def initialize(group:, current_user: nil, skip_authorization: false)
      @group = group
      @current_user = current_user
      @skip_authorization = skip_authorization
    end

    def execute
      return error_not_root_group unless group.root?
      return error_not_in_default_organization unless in_default_organization?
      return error_insufficient_permissions if !skip_authorization && !can?(current_user, :admin_group, group) # rubocop:disable Gitlab/Authz/PermissionCheck -- this matches the ability check in app/controllers/groups/application_controller.rb#authorize_admin_group!

      create_result = create_organization
      return create_result if create_result.error?

      organization = create_result.payload[:organization]

      transfer_result = transfer_group_to(organization)
      return transfer_result if transfer_result.error?

      ServiceResponse.success(payload: { organization: organization })
    end

    private

    attr_reader :group, :current_user, :skip_authorization

    def in_default_organization?
      Organization.default?(group.organization_id)
    end

    def create_organization
      result = create_organization_with_path(group.path)
      result = create_organization_with_path(fallback_path) if result.error? && path_validation_error?(result)

      return result if result.success?

      ServiceResponse.error(message: result.message, reason: :organization_not_created)
    end

    def create_organization_with_path(path)
      Organizations::CreateService.new(
        current_user: current_user,
        params: {
          name: group.name,
          path: path,
          state: :unconfirmed,
          visibility_level: group.visibility_level
        }
      ).execute(skip_authorization: skip_authorization)
    end

    # The group path may already be taken by another organization, or be
    # reserved for organizations but not for groups.
    def fallback_path
      "organization-#{group.id}"
    end

    def path_validation_error?(result)
      result.message.to_s.include?('Path')
    end

    def transfer_group_to(organization)
      result = Organizations::Transfer::TopLevelGroupService.new(
        groups: group,
        new_organization: organization,
        current_user: current_user,
        skip_authorization: skip_authorization
      ).execute

      return ServiceResponse.success if result.success?

      # The organization is returned so callers can report or clean up the
      # organization that was created but left without its group.
      ServiceResponse.error(
        message: result.message,
        reason: :group_not_transferred,
        payload: { organization: organization }
      )
    end

    def error_insufficient_permissions
      ServiceResponse.error(
        message: [_('You have insufficient permissions to create an organization from this group.')],
        reason: :insufficient_permissions
      )
    end

    def error_not_root_group
      ServiceResponse.error(
        message: s_('Organization|Only top-level groups can be moved to a new organization.'),
        reason: :not_root_group
      )
    end

    def error_not_in_default_organization
      ServiceResponse.error(
        message: s_('Organization|Group is already in an organization.'),
        reason: :not_in_default_organization
      )
    end
  end
end
