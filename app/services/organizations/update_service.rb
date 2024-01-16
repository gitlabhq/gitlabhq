# frozen_string_literal: true

module Organizations
  class UpdateService < ::Organizations::BaseService
    attr_reader :organization

    def initialize(organization, current_user:, params: {})
      @organization = organization
      @current_user = current_user
      @params = params.dup

      build_organization_detail_attributes
      # TODO: Remove explicit passing of id once https://github.com/rails/rails/issues/48714 is resolved.
      @params[:organization_detail_attributes][:id] = organization.id
    end

    def execute
      return error_no_permissions unless allowed?

      if params[:organization_detail_attributes].key?(:avatar) && params[:organization_detail_attributes][:avatar].nil?
        organization.remove_avatar!
      end

      if organization.update(params)
        ServiceResponse.success(payload: { organization: organization })
      else
        error_updating
      end
    end

    private

    def allowed?
      current_user&.can?(:admin_organization, organization)
    end

    def error_no_permissions
      ServiceResponse.error(message: [_('You have insufficient permissions to update the organization')])
    end

    def error_updating
      message = organization.errors.full_messages || _('Failed to update organization')

      ServiceResponse.error(payload: { organization: organization }, message: Array(message))
    end
  end
end
