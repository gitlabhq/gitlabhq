# frozen_string_literal: true

module Users
  class BannedUser < ApplicationRecord
    self.primary_key = :user_id

    belongs_to :user
    has_one :credit_card_validation, class_name: '::Users::CreditCardValidation', primary_key: 'user_id',
      foreign_key: 'user_id', inverse_of: :banned_user

    validates :user, presence: true
    validates :user_id, uniqueness: { message: N_("banned user already exists") }
  end
end

Users::BannedUser.prepend_mod_with('Users::BannedUser')
