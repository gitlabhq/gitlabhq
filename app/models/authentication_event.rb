# frozen_string_literal: true

class AuthenticationEvent < ApplicationRecord
  include UsageStatistics

  TWO_FACTOR = 'two-factor'
  TWO_FACTOR_U2F = 'two-factor-via-u2f-device'
  TWO_FACTOR_WEBAUTHN = 'two-factor-via-webauthn-device'
  STANDARD = 'standard'
  STATIC_PROVIDERS = [TWO_FACTOR, TWO_FACTOR_U2F, TWO_FACTOR_WEBAUTHN, STANDARD].freeze

  belongs_to :user, optional: true

  validates :provider, :user_name, :result, presence: true
  validates :ip_address, ip_address: true

  enum result: {
    failed: 0,
    success: 1
  }

  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :ldap, -> { where('provider LIKE ?', 'ldap%') }
  scope :for_user, ->(user) { where(user: user) }
  scope :order_by_created_at_desc, -> { reorder(created_at: :desc) }

  def self.providers
    STATIC_PROVIDERS | Devise.omniauth_providers.map(&:to_s)
  end

  def self.initial_login_or_known_ip_address?(user, ip_address)
    !where(user_id: user).exists? ||
      where(user_id: user, ip_address: ip_address).success.exists?
  end

  def self.most_used_ip_address_for_user(user)
    select('mode() within group (order by ip_address) as ip_address').find_by(user: user).ip_address
  end
end
