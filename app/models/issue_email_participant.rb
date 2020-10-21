# frozen_string_literal: true

class IssueEmailParticipant < ApplicationRecord
  belongs_to :issue

  validates :email, presence: true, uniqueness: { scope: [:issue_id] }
  validates :issue, presence: true
  validate :validate_email_format

  def validate_email_format
    self.errors.add(:email, I18n.t(:invalid, scope: 'valid_email.validations.email')) unless ValidateEmail.valid?(self.email)
  end
end
