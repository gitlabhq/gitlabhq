# frozen_string_literal: true

module Organizations
  class CreateService < ::Organizations::BaseService
    def execute(skip_authorization: false)
      return error_no_permissions unless skip_authorization || can?(current_user, :create_organization)

      add_organization_owner_attributes unless skip_authorization
      organization = Organization.new(params)

      saved = Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification
                       .allow_cross_database_modification_within_transaction(
                         url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/438757'
                       ) do
        organization.save
      end

      if saved
        ServiceResponse.success(payload: { organization: organization })
      else
        error_creating(organization)
      end
    rescue Cells::TransactionRecord::Error
      error_creating(organization)
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
  end
end
