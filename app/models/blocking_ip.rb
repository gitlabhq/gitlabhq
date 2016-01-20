class BlockingIp < ActiveRecord::Base
  belongs_to :user

  validates :ip,
            presence: true,
            uniqueness: { message: 'has already been taken by IP Blacklist or IP Whitelist' },
            ip: { message: 'allows only valid IP addresses' }

  scope :whitelisted, -> { where(type: 'WhitelistedIp') }
  scope :blacklisted, -> { where(type: 'BlacklistedIp') }
end
