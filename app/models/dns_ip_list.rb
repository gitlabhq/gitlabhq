class DnsIpList < ActiveRecord::Base
  belongs_to :user

  validates :domain,
            presence: true,
            uniqueness: true

  validates :weight,
            presence: true,
            numericality: { greater_than:0 }

  scope :whitelist, -> { where(type: 'DnsIpWhitelist') }
  scope :blacklist, -> { where(type: 'DnsIpBlacklist') }
end
