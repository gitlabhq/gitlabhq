# frozen_string_literal: true

module Organizations
  class OrganizationUser < ApplicationRecord
    belongs_to :organization, inverse_of: :organization_users, optional: false
    belongs_to :user, inverse_of: :organization_users, optional: false

    validates :user, uniqueness: { scope: :organization_id }
    validates :access_level, presence: true

    enum access_level: {
      # Until we develop more access_levels, we really don't know if the default access_level will be what we think of
      # as a guest. For now, we'll set to same value as guest, but call it default to denote the current ambivalence.
      default: Gitlab::Access::GUEST,
      owner: Gitlab::Access::OWNER
    }

    scope :owners, -> { where(access_level: Gitlab::Access::OWNER) }

    def self.create_default_organization_record_for(user_id, user_is_admin:)
      Organizations::OrganizationUser.upsert(
        {
          organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
          user_id: user_id,
          access_level: default_organization_access_level(user_is_admin: user_is_admin)
        },
        unique_by: [:organization_id, :user_id]
      )
    end

    def self.update_default_organization_record_for(user_id, user_is_admin:)
      find_or_initialize_by(
        user_id: user_id, organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID
      ).tap do |record|
        record.access_level = default_organization_access_level(user_is_admin: user_is_admin)
        record.save
      end
    end

    def self.default_organization_access_level(user_is_admin: false)
      if user_is_admin
        :owner
      else
        :default
      end
    end
  end
end
