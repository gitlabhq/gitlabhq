# frozen_string_literal: true

module Organizations
  class OrganizationUserPolicy < BasePolicy
    delegate :organization

    condition(:record_belongs_to_self) { @user && @subject.user == @user }
    condition(:last_owner) { @subject.last_owner? }
    condition(:home_organization_membership) { @subject.organization_id == @subject.user&.organization_id }

    rule { can?(:update_organization) }.enable :create_organization_user

    rule { can?(:update_organization) }.policy do
      enable :update_organization_user
      enable :delete_organization_user
    end

    rule { record_belongs_to_self }.enable :delete_organization_user

    rule { home_organization_membership }.prevent :delete_organization_user

    rule { last_owner }.policy do
      prevent :update_organization_user
      prevent :delete_organization_user
    end
  end
end
