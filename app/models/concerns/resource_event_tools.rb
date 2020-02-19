# frozen_string_literal: true

module ResourceEventTools
  extend ActiveSupport::Concern

  included do
    belongs_to :user

    validates :user, presence: { unless: :importing? }, on: :create

    validate :exactly_one_issuable

    scope :created_after, ->(time) { where('created_at > ?', time) }
  end

  def exactly_one_issuable
    issuable_count = self.class.issuable_attrs.count { |attr| self["#{attr}_id"] }

    return true if issuable_count == 1

    # if none of issuable IDs is set, check explicitly if nested issuable
    # object is set, this is used during project import
    if issuable_count == 0 && importing?
      issuable_count = self.class.issuable_attrs.count { |attr| self.public_send(attr) } # rubocop:disable GitlabSecurity/PublicSend

      return true if issuable_count == 1
    end

    errors.add(:base, "Exactly one of #{self.class.issuable_attrs.join(', ')} is required")
  end
end
