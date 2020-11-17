# frozen_string_literal: true

class AuthenticationEvent < ApplicationRecord
  include UsageStatistics

  TWO_FACTOR = 'two-factor'.freeze
  TWO_FACTOR_U2F = 'two-factor-via-u2f-device'.freeze
  TWO_FACTOR_WEBAUTHN = 'two-factor-via-webauthn-device'.freeze
  STANDARD = 'standard'.freeze
  STATIC_PROVIDERS = [TWO_FACTOR, TWO_FACTOR_U2F, TWO_FACTOR_WEBAUTHN, STANDARD].freeze

  belongs_to :user, optional: true

  validates :provider, :user_name, :result, presence: true
  validates :ip_address, ip_address: true

  enum result: {
    failed: 0,
    success: 1
  }

  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :ldap, -> { where('provider LIKE ?', 'ldap%')}

  def self.providers
    STATIC_PROVIDERS | Devise.omniauth_providers.map(&:to_s)
  end
end
