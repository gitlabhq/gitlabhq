# frozen_string_literal: true

class AuthenticationEvent < ApplicationRecord
  include UsageStatistics

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
    distinct.pluck(:provider)
  end
end
