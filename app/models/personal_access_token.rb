class PersonalAccessToken < ActiveRecord::Base
  include TokenAuthenticatable
  add_authentication_token_field :token

  belongs_to :user

  scope :active, -> { where(revoked: false).where("expires_at >= NOW() OR expires_at IS NULL") }
  scope :inactive, -> { where("revoked = true OR expires_at < NOW()") }

  def self.generate(params)
    personal_access_token = self.new(params)
    personal_access_token.ensure_token
    personal_access_token
  end

  def revoke!
    self.revoked = true
    self.save
  end
end
