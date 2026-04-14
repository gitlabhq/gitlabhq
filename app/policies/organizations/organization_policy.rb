# frozen_string_literal: true

module Organizations
  class OrganizationPolicy < BasePolicy
    condition(:organization_user) { @subject.user?(@user) }

    desc "User owns the organization"
    condition(:organization_owner) { owns_organization?(@subject) }

    desc 'Organization is public'
    condition(:public_organization, scope: :subject, score: 0) { @subject.public? }

    desc 'Organization admin area feature flag is enabled'
    condition(:organization_admin_area_enabled, scope: :subject) do
      Feature.enabled?(:org_admin_area, @subject)
    end

    rule { public_organization }.policy do
      enable :read_organization
      enable :read_work_item_type
    end

    rule { admin }.policy do
      enable :admin_organization
      enable :access_organization_admin_area
      enable :create_group
      enable :read_organization
      enable :read_organization_user
      enable :read_work_item_type
    end

    rule { organization_owner }.policy do
      enable :admin_organization
      enable :access_organization_admin_area
      enable :read_organization_user
    end

    rule { ~organization_admin_area_enabled }.policy do
      prevent :access_organization_admin_area
    end

    rule { organization_user }.policy do
      enable :read_organization
      enable :create_group
      enable :read_work_item_type
    end
  end
end

Organizations::OrganizationPolicy.prepend_mod_with('Organizations::OrganizationPolicy')
