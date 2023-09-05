# frozen_string_literal: true

module Organizations
  class OrganizationUserPolicy < BasePolicy
    delegate :organization
  end
end
