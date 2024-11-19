# frozen_string_literal: true

module Organizations
  class OrganizationUser < ApplicationRecord
    include ActiveModel::Dirty

    belongs_to :organization, inverse_of: :organization_users, optional: false
    belongs_to :user, inverse_of: :organization_users, optional: false

    validates :user, uniqueness: { scope: :organization_id }
    validates :access_level, presence: true

    validate :last_owner_access_level_change, if: :access_level_changed?

    before_destroy :ensure_user_has_an_organization

    enum access_level: {
      # Until we develop more access_levels, we really don't know if the default access_level will be what we think of
      # as a guest. For now, we'll set to same value as guest, but call it default to denote the current ambivalence.
      default: Gitlab::Access::GUEST,
      owner: Gitlab::Access::OWNER
    }

    scope :owners, -> { where(access_level: Gitlab::Access::OWNER) }
    scope :in_organization, ->(organization) { where(organization: organization) }
    scope :with_active_users, -> { joins(:user).merge(User.active) }
    scope :by_user, ->(user) { where(user: user) }

    def self.create_default_organization_record_for(user_id, user_is_admin:)
      return if Organizations::Organization.default_organization.nil?

      upsert(
        {
          organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
          user_id: user_id,
          access_level: default_organization_access_level(user_is_admin: user_is_admin)
        },
        unique_by: [:organization_id, :user_id]
      )
    end

    def self.default_organization_access_level(user_is_admin: false)
      if user_is_admin
        :owner
      else
        :default
      end
    end

    def self.create_organization_record_for(user_id, organization_id)
      # we try to find a record if it exists.
      find_by(user_id: user_id, organization_id: organization_id) ||

        # If not, we try to create it with `upsert`.
        # We use upsert for these reasons:
        #    - No subtransactions
        #    - Due to the use of `on_duplicate: :skip`, we are essentially issuing a `ON CONFLICT DO NOTHING`.
        #       - Postgres will take care of skipping the record without errors if a similar record was created
        #         by then in another thread.
        #       - There is no explicit error being thrown because we said "ON CONFLICT DO NOTHING".
        #         With this we avoid both the problems with subtransactions that could arise when we upgrade Rails,
        #         see https://gitlab.com/gitlab-org/gitlab/-/issues/439567, and also with race conditions.

        upsert(
          { organization_id: organization_id, user_id: user_id, access_level: :default },
          unique_by: [:organization_id, :user_id],
          on_duplicate: :skip # Do not change access_level, could make :owner :default
        )
    end

    def last_owner?
      return false unless owner?

      # Try to keep the last active user as owner
      return other_owners.with_active_users.empty? if user.active?

      other_owners.empty?
    end

    private

    def other_owners
      @other_owners ||= organization.organization_users.owners.id_not_in(id)
    end

    def ensure_user_has_an_organization
      return unless user

      return unless user.organization_users.where.not(id: id).empty?

      errors.add(:base, _('A user must associate with at least one organization'))
    end

    def last_owner_access_level_change
      return unless access_level_was == 'owner' && other_owners.empty?

      errors.add(:base, _('You cannot change the access of the last owner from the organization'))
    end
  end
end
