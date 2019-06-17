# frozen_string_literal: true

class IssueTrackerData < ApplicationRecord
  belongs_to :service

  delegate :activated?, to: :service, allow_nil: true

  validates :service, presence: true
  validates :project_url, presence: true, public_url: { enforce_sanitization: true }, if: :activated?
  validates :issues_url, presence: true, public_url: { enforce_sanitization: true }, if: :activated?
  validates :new_issue_url, public_url: { enforce_sanitization: true }, if: :activated?

  def self.encryption_options
    {
      key: Settings.attr_encrypted_db_key_base_32,
      encode: true,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm'
    }
  end

  attr_encrypted :project_url, encryption_options
  attr_encrypted :issues_url, encryption_options
  attr_encrypted :new_issue_url, encryption_options
end
