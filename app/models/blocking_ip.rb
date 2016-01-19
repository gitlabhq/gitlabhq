class BlockingIp < ActiveRecord::Base
  belongs_to :user

  validates :ip,
            presence: true,
            uniqueness: { message: 'has already been taken by IP Blacklist or IP Whitelist' },
            format: { with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/,
                      message: 'allows only valid IP addresses' }

  scope :whitelisted, -> { where(type: 'WhitelistedIp') }
  scope :blacklisted, -> { where(type: 'BlacklistedIp') }
end
