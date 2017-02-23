class PersonalAccessToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  serialize :scopes, Array

  belongs_to :user

  before_save :ensure_token

  default_scope { where(impersonation: false) }
  scope :active, -> { where(revoked: false).where("expires_at >= NOW() OR expires_at IS NULL") }
  scope :inactive, -> { where("revoked = true OR expires_at < NOW()") }
  scope :impersonation, -> { unscoped.where(impersonation: true) }
  scope :with_impersonation_tokens, ->  { unscoped }

  def revoke!
    self.revoked = true
    self.save
  end

  def active?
    !revoked? && !expired?
  end
end
