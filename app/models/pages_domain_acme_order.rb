# frozen_string_literal: true

class PagesDomainAcmeOrder < ApplicationRecord
  belongs_to :pages_domain

  scope :expired, -> { where("expires_at < ?", Time.current) }

  validates :pages_domain, presence: true
  validates :expires_at, presence: true
  validates :url, presence: true
  validates :challenge_token, presence: true
  validates :challenge_file_content, presence: true
  validates :private_key, presence: true

  attr_encrypted :private_key,
                 mode: :per_attribute_iv,
                 key: Settings.attr_encrypted_db_key_base_32,
                 algorithm: 'aes-256-gcm',
                 encode: true

  def self.find_by_domain_and_token(domain_name, challenge_token)
    joins(:pages_domain).find_by(pages_domains: { domain: domain_name }, challenge_token: challenge_token)
  end
end
