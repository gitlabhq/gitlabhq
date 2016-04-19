class PersonalAccessToken < ActiveRecord::Base
  belongs_to :user

  scope :active, -> { where(revoked: false).where("expires_at >= :current OR expires_at IS NULL", current: Time.current) }
  scope :inactive, -> { where("revoked = true OR expires_at < :current", current: Time.current) }

  def self.generate(params)
    personal_access_token = self.new(params)
    personal_access_token.token = Devise.friendly_token(50)
    personal_access_token
  end

  def revoke!
    self.revoked = true
    self.save
  end
end
