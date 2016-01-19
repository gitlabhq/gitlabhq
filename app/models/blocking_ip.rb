class BlockingIp < ActiveRecord::Base
  belongs_to :user

  validates :ip,
            presence: true,
            uniqueness: true

  scope :whitelisted, -> { where(type: 'WhitelistedIp') }
  scope :blacklisted, -> { where(type: 'BlacklistedIp') }
end
