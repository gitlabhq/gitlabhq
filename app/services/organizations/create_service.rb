# frozen_string_literal: true

module Organizations
  class CreateService < ::Organizations::BaseService
    def execute
      return error_no_permissions unless can?(current_user, :create_organization)
      return error_feature_flag unless Feature.enabled?(:allow_organization_creation, current_user)

      add_organization_owner_attributes
      organization = Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification
                       .allow_cross_database_modification_within_transaction(
                         url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/438757'
                       ) do
        Organization.create(params)
      end

      if organization.persisted?
        ServiceResponse.success(payload: { organization: organization })
      else
        error_creating(organization)
      end
    end

    private

    def add_organization_owner_attributes
      @params[:organization_users_attributes] = [{ user: current_user, access_level: :owner }]
    end

    def error_no_permissions
      ServiceResponse.error(message: [_('You have insufficient permissions to create organizations')])
    end

    def error_creating(organization)
      message = organization.errors.full_messages || _('Failed to create organization')

      ServiceResponse.error(message: Array(message))
    end

    def error_feature_flag
      # Don't translate feature flag error because it's temporary.
      ServiceResponse.error(message: ['Feature flag `allow_organization_creation` is not enabled for this user.'])
    end
  end
end
