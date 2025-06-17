# frozen_string_literal: true

module Organizations
  class OrganizationUserDetail < ApplicationRecord
    belongs_to :organization, inverse_of: :organization_user_details, optional: false
    belongs_to :user, inverse_of: :organization_user_details, optional: false

    validates :username, presence: true, uniqueness: { scope: :organization_id }
    validates :display_name, presence: true
  end
end
