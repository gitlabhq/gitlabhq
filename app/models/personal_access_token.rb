class PersonalAccessToken < ActiveRecord::Base
  belongs_to :user

  scope :active, -> { where.not(revoked: true) }

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
