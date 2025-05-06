# frozen_string_literal: true

module Organizations
  class OrganizationUserAlias < ApplicationRecord
    belongs_to :organization, inverse_of: :organization_user_aliases, optional: false
    belongs_to :user, inverse_of: :organization_user_aliases, optional: false

    validates :username, presence: true, uniqueness: { scope: :organization_id }
  end
end
