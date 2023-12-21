# frozen_string_literal: true

module Organizations
  class OrganizationPolicy < BasePolicy
    condition(:organization_user) { @subject.user?(@user) }

    desc 'Organization is public'
    condition(:public_organization, scope: :subject, score: 0) { true }

    rule { public_organization }.policy do
      enable :read_organization
    end

    rule { admin }.policy do
      enable :admin_organization
      enable :read_organization
      enable :read_organization_user
    end

    rule { organization_user }.policy do
      enable :admin_organization
      enable :read_organization
      enable :read_organization_user
    end
  end
end
