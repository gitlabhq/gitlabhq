class DnsIpList < ActiveRecord::Base
  belongs_to :user

  validates :domain,
            presence: true,
            uniqueness: { message: 'has already been taken by DNS Blacklist or DNS Whitelist' }

  validates :weight,
            presence: true,
            numericality: { greater_than:0, less_than_or_equal: 100 }

  scope :whitelist, -> { where(type: 'DnsIpWhitelist') }
  scope :blacklist, -> { where(type: 'DnsIpBlacklist') }
end
