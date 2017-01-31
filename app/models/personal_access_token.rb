class PersonalAccessToken < ActiveRecord::Base
  include TokenAuthenticatable
  add_authentication_token_field :token

  serialize :scopes, Array

  belongs_to :user

  scope :active, -> { where(revoked: false).where("expires_at >= NOW() OR expires_at IS NULL") }
  scope :inactive, -> { where("revoked = true OR expires_at < NOW()") }

  validate :validate_scopes

  def self.generate(params)
    personal_access_token = self.new(params)
    personal_access_token.ensure_token
    personal_access_token
  end

  def revoke!
    self.revoked = true
    self.save
  end

  protected

  def validate_scopes
    unless Set.new(scopes.map(&:to_sym)).subset?(Set.new(Gitlab::Auth::API_SCOPES))
      errors.add :scopes, "can only contain API scopes"
    end
  end
end
