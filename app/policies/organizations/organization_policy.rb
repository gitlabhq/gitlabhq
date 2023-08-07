# frozen_string_literal: true

module Organizations
  class OrganizationPolicy < BasePolicy
    condition(:organization_user) { @subject.user?(@user) }

    rule { admin }.policy do
      enable :admin_organization
      enable :read_organization
    end

    rule { organization_user }.policy do
      enable :read_organization
    end
  end
end
