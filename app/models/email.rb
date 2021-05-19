# frozen_string_literal: true

class Email < ApplicationRecord
  include Sortable
  include Gitlab::SQL::Pattern

  belongs_to :user, optional: false

  validates :email, presence: true, uniqueness: true
  validate :validate_email_format
  validate :unique_email, if: ->(email) { email.email_changed? }

  scope :confirmed, -> { where.not(confirmed_at: nil) }

  after_commit :update_invalid_gpg_signatures, if: -> { previous_changes.key?('confirmed_at') }

  devise :confirmable

  # This module adds async behaviour to Devise emails
  # and should be added after Devise modules are initialized.
  include AsyncDeviseEmail

  self.reconfirmable = false # currently email can't be changed, no need to reconfirm

  delegate :username, :can?, :pending_invitations, :accept_pending_invitations!, to: :user

  def email=(value)
    write_attribute(:email, value.downcase.strip)
  end

  def unique_email
    self.errors.add(:email, 'has already been taken') if User.exists?(email: self.email)
  end

  def validate_email_format
    self.errors.add(:email, I18n.t(:invalid, scope: 'valid_email.validations.email')) unless ValidateEmail.valid?(self.email)
  end

  # once email is confirmed, update the gpg signatures
  def update_invalid_gpg_signatures
    user.update_invalid_gpg_signatures if confirmed?
  end
end
