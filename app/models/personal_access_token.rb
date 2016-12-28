class PersonalAccessToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  serialize :scopes, Array

  belongs_to :user

  default_scope { where(impersonation: false) }
  scope :active, -> { where(revoked: false).where("expires_at >= NOW() OR expires_at IS NULL") }
  scope :inactive, -> { where("revoked = true OR expires_at < NOW()") }
  scope :impersonation, -> { where(impersonation: true) }

  class << self
    alias_method :and_impersonation_tokens, :unscoped

    def generate(params)
      personal_access_token = self.new(params)
      personal_access_token.ensure_token
      personal_access_token
    end
  end

  def revoke!
    self.revoked = true
    self.save
  end

  def active?
    !revoked? && !expired?
  end
end
