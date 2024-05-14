# frozen_string_literal: true

module Organizations
  class OrganizationPolicy < BasePolicy
    condition(:organization_user) { @subject.user?(@user) }
    condition(:organization_owner) { @subject.owner?(@user) }

    desc 'Organization is public'
    condition(:public_organization, scope: :subject, score: 0) { @subject.public? }

    rule { public_organization }.policy do
      enable :read_organization
    end

    rule { admin }.policy do
      enable :admin_organization
      enable :create_group
      enable :read_organization
      enable :read_organization_user
    end

    rule { organization_owner }.policy do
      enable :admin_organization
    end

    rule { organization_user }.policy do
      enable :read_organization
      enable :read_organization_user
      enable :create_group
    end
  end
end

Organizations::OrganizationPolicy.prepend_mod_with('Organizations::OrganizationPolicy')
