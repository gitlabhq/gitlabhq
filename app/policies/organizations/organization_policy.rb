# frozen_string_literal: true

module Organizations
  class OrganizationPolicy < BasePolicy
    condition(:organization_user) { @subject.user?(@user) }

    desc "User owns the organization"
    condition(:organization_owner) { owns_organization?(@subject) }

    desc 'Organization is public'
    condition(:public_organization, scope: :subject, score: 0) { @subject.public? }

    desc 'Organization admin area is enabled'
    condition(:organization_admin_area_enabled, scope: :subject) do
      Organizations::Release.enabled?(:org_admin_area, @subject)
    end

    desc "Organization is the default"
    condition(:default_organization, scope: :subject, score: 0) { @subject.default? }

    rule { public_organization }.policy do
      enable :read_organization
      enable :read_work_item_type
    end

    rule { admin }.policy do
      enable(*Authz::Role.get(:admin).permissions(:organization))
    end

    rule { organization_owner }.policy do
      enable :access_organization_admin_area
      enable :delete_organization
      enable :read_organization_user
      enable :transfer_group
      enable :update_organization
    end

    rule { default_organization }.prevent :delete_organization

    rule { blocked | deactivated | inactive }.policy do
      prevent :delete_organization
      prevent :restore_organization
    end

    rule { ~organization_admin_area_enabled }.policy do
      prevent :access_organization_admin_area
    end

    rule { organization_user }.policy do
      enable :read_organization
      enable :create_group
      enable :read_work_item_type
      enable :read_artifact_registry
    end
  end
end

Organizations::OrganizationPolicy.prepend_mod_with('Organizations::OrganizationPolicy')
