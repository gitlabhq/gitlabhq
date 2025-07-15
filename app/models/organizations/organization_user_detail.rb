# frozen_string_literal: true

module Organizations
  class OrganizationUserDetail < ApplicationRecord
    include Referable

    belongs_to :organization, inverse_of: :organization_user_details, optional: false
    belongs_to :user, inverse_of: :organization_user_details, optional: false

    validates :username, presence: true, uniqueness: { scope: :organization_id }
    validates :display_name, presence: true

    validate :no_namespace_conflicts

    scope :for_references, -> { includes(:organization, :user) }
    scope :for_organization, ->(organization) { where(organization: organization) }
    scope :with_usernames, ->(*usernames) {
      uniq_usernames = usernames.flatten.compact.uniq
      return none if uniq_usernames.blank?

      downcase_usernames = uniq_usernames.map(&:downcase)

      where("LOWER(username) IN (?)", downcase_usernames)
    }

    # Referable methods should be the same as User
    def reference_prefix
      '@'
    end

    def reference_pattern
      @reference_pattern ||=
        %r{
          (?<!\w)
          #{Regexp.escape(reference_prefix)}
          (?<user>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
        }x
    end

    def to_reference(*)
      "#{reference_prefix}#{username}"
    end

    def no_namespace_conflicts
      return if username.blank?

      return unless Namespace.username_reserved_for_organization?(
        username,
        organization,
        excluding: user.namespace
      )

      errors.add(:username, _('has already been taken'))
    end
  end
end
