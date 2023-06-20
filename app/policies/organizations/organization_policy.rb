# frozen_string_literal: true

module Organizations
  class OrganizationPolicy < BasePolicy
    rule { admin }.policy do
      enable :admin_organization
    end
  end
end
