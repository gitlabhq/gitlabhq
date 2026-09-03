# frozen_string_literal: true

module Organizations
  class OrganizationPolicy < BasePolicy
    condition(:organization_user) { @subject.user?(@user) }

    desc "User owns the organization"
    condition(:organization_owner) { owns_organization?(@subject) }

    desc 'Organization is public'
    condition(:public_organization, scope: :subject, score: 0) { @subject.public? }

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
      enable(*Authz::Role.get(:organization_owner).permissions(:organization))
    end

    rule { default_organization }.prevent :delete_organization

    rule { blocked | deactivated | inactive }.policy do
      prevent :delete_organization
      prevent :restore_organization
    end

    rule { organization_user }.policy do
      enable(*Authz::Role.get(:organization_user).permissions(:organization))
    end
  end
end

Organizations::OrganizationPolicy.prepend_mod_with('Organizations::OrganizationPolicy')
