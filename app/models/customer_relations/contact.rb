# frozen_string_literal: true

class CustomerRelations::Contact < ApplicationRecord
  include StripAttribute

  self.table_name = "customer_relations_contacts"

  belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'group_id'
  belongs_to :organization, optional: true

  strip_attributes! :phone, :first_name, :last_name

  enum state: {
    inactive: 0,
    active: 1
  }

  validates :group, presence: true
  validates :phone, length: { maximum: 32 }
  validates :first_name, presence: true, length: { maximum: 255 }
  validates :last_name, presence: true, length: { maximum: 255 }
  validates :email, length: { maximum: 255 }
  validates :description, length: { maximum: 1024 }
  validate :validate_email_format

  private

  def validate_email_format
    return unless email

    self.errors.add(:email, I18n.t(:invalid, scope: 'valid_email.validations.email')) unless ValidateEmail.valid?(self.email)
  end
end
