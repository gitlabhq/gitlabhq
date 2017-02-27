class PersonalAccessToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  serialize :scopes, Array

  belongs_to :user

  before_save :ensure_token

  scope :active, -> { where("revoked = false AND (expires_at >= NOW() OR expires_at IS NULL)") }
  scope :inactive, -> { where("revoked = true OR expires_at < NOW()") }
  scope :with_impersonation, -> { where(impersonation: true) }
  scope :without_impersonation, -> { where(impersonation: false) }

  def revoke!
    self.revoked = true
    self.save
  end

  def active?
    !revoked? && !expired?
  end
end
