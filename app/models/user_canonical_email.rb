# frozen_string_literal: true

class UserCanonicalEmail < ApplicationRecord
  validates :canonical_email, presence: true
  validates :canonical_email, format: { with: Devise.email_regexp }

  belongs_to :user, inverse_of: :user_canonical_email
  belongs_to :banned_user, class_name: '::Users::BannedUser', foreign_key: :user_id,
    inverse_of: :user_canonical_email
end
