# frozen_string_literal: true

class CustomerRelations::Contact < ApplicationRecord
  include StripAttribute

  self.table_name = "customer_relations_contacts"

  belongs_to :group, -> { where(type: Group.sti_name) }, foreign_key: 'group_id'
  belongs_to :organization, optional: true
  has_many :issue_contacts, inverse_of: :contact
  has_many :issues, through: :issue_contacts, inverse_of: :customer_relations_contacts

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
  validates :email, uniqueness: { scope: :group_id }
  validate :validate_email_format
  validate :validate_root_group

  def self.reference_prefix
    '[contact:'
  end

  def self.reference_prefix_quoted
    '["contact:'
  end

  def self.reference_postfix
    ']'
  end

  def self.find_ids_by_emails(group, emails)
    raise ArgumentError, "Cannot lookup more than #{MAX_PLUCK} emails" if emails.length > MAX_PLUCK

    where(group: group, email: emails).pluck(:id)
  end

  def self.exists_for_group?(group)
    return false unless group

    exists?(group: group)
  end

  private

  def validate_email_format
    return unless email

    self.errors.add(:email, I18n.t(:invalid, scope: 'valid_email.validations.email')) unless ValidateEmail.valid?(self.email)
  end

  def validate_root_group
    return if group&.root?

    self.errors.add(:base, _('contacts can only be added to root groups'))
  end
end
