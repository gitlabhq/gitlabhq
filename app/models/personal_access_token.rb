class PersonalAccessToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  serialize :scopes, Array # rubocop:disable Cop/ActiverecordSerialize

  belongs_to :user

  before_save :ensure_token

  scope :active, -> { where("revoked = false AND (expires_at >= NOW() OR expires_at IS NULL)") }
  scope :inactive, -> { where("revoked = true OR expires_at < NOW()") }
  scope :with_impersonation, -> { where(impersonation: true) }
  scope :without_impersonation, -> { where(impersonation: false) }

  validates :scopes, presence: true
  validate :validate_api_scopes

  def revoke!
    self.revoked = true
    self.save
  end

  def active?
    !revoked? && !expired?
  end

  protected

  def validate_api_scopes
    unless scopes.all? { |scope| Gitlab::Auth::API_SCOPES.include?(scope.to_sym) }
      errors.add :scopes, "can only contain API scopes"
    end
  end
end
