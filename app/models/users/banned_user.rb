# frozen_string_literal: true

module Users
  class BannedUser < ApplicationRecord
    include EachBatch

    self.primary_key = :user_id

    belongs_to :user
    has_one :credit_card_validation, class_name: '::Users::CreditCardValidation', primary_key: 'user_id',
      foreign_key: 'user_id', inverse_of: :banned_user
    has_many :emails, primary_key: 'user_id', foreign_key: 'user_id', inverse_of: :banned_user

    validates :user, presence: true
    validates :user_id, uniqueness: { message: N_("banned user already exists") }

    scope :by_detumbled_email, ->(email) do
      return none if email.blank?

      joins(:emails)
        .where({ emails: { detumbled_email: ::Gitlab::Utils::Email.normalize_email(email) } })
        .where.not({ emails: { confirmed_at: nil } })
    end

    scope :by_user_ids, ->(ids) { where(user_id: ids) }
    scope :created_before, ->(interval) { where(created_at: ...interval) }
    scope :without_deleted_projects, -> { where(projects_deleted: false) }
  end
end

Users::BannedUser.prepend_mod_with('Users::BannedUser')
