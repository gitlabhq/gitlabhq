# frozen_string_literal: true

module Organizations
  class ActivateService
    attr_reader :current_user, :params, :organization

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
      @organization = Organizations::Organization.find_by_id(@params[:organization_id])
    end

    def execute
      return error(_('Organization not found')) unless organization
      return error(_('Insufficient permissions')) unless allowed?
      return error(_('Organization must be confirmed')) unless organization.state == 'confirmed'

      response = nil

      ApplicationRecord.transaction do
        transfer_result = transfer_top_level_groups

        if transfer_result.error?
          response = transfer_result
          raise ActiveRecord::Rollback
        end

        create_organization_users

        organization.activate

        if organization.active?
          response = ServiceResponse.success(payload: { organization: organization })
        else
          response = error(
            organization.errors.full_messages.to_sentence.presence || _('Organization could not be activated')
          )
          raise ActiveRecord::Rollback
        end
      end

      response
    end

    private

    def transfer_top_level_groups
      aggregated_errors = []

      organization.groups.top_level.find_each do |group|
        result = Organizations::Transfer::GroupsService.new(
          group: group,
          new_organization: organization,
          current_user: current_user
        ).execute

        next if result.success?
        # The group and all of its descendants are already in the target
        # organization, so there is nothing to do for this group.
        next if already_transferred_error?(result)

        aggregated_errors << result
      end

      return ServiceResponse.success if aggregated_errors.empty?

      ServiceResponse.error(
        message: aggregated_errors.map(&:message).join('; '),
        payload: { organization: organization, failed_transfers: aggregated_errors }
      )
    end

    def create_organization_users
      Organizations::Transfer::OrganizationUsersService.new(organization: organization).execute
    end

    def already_transferred_error?(result)
      result.reason == :already_transferred
    end

    def allowed?
      current_user&.can?(:update_organization, organization)
    end

    def error(message)
      ServiceResponse.error(message: message, payload: { organization: organization })
    end
  end
end
