# frozen_string_literal: true

module Organizations
  class OrganizationUser < ApplicationRecord
    belongs_to :organization, inverse_of: :organization_users, optional: false
    belongs_to :user, inverse_of: :organization_users, optional: false
  end
end
