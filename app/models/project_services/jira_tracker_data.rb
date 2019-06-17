# frozen_string_literal: true

class JiraTrackerData < ApplicationRecord
  belongs_to :service

  delegate :activated?, to: :service, allow_nil: true

  validates :service, presence: true
  validates :url, public_url: { enforce_sanitization: true }, presence: true, if: :activated?
  validates :api_url, public_url: { enforce_sanitization: true }, allow_blank: true
  validates :username, presence: true, if: :activated?
  validates :password, presence: true, if: :activated?
  validates :jira_issue_transition_id,
            format: { with: Gitlab::Regex.jira_transition_id_regex, message: s_("JiraService|transition ids can have only numbers which can be split with , or ;") },
            allow_blank: true

  def self.encryption_options
    {
      key: Settings.attr_encrypted_db_key_base_32,
      encode: true,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm'
    }
  end

  attr_encrypted :url, encryption_options
  attr_encrypted :api_url, encryption_options
  attr_encrypted :username, encryption_options
  attr_encrypted :password, encryption_options
end
