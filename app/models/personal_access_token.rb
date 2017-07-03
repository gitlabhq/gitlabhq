class PersonalAccessToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  serialize :scopes, Array # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :user

  before_save :ensure_token

  scope :active, -> { where("revoked = false AND (expires_at >= NOW() OR expires_at IS NULL)") }
  scope :inactive, -> { where("revoked = true OR expires_at < NOW()") }
  scope :with_impersonation, -> { where(impersonation: true) }
  scope :without_impersonation, -> { where(impersonation: false) }

  validates :scopes, presence: true
  validate :validate_scopes

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked? && !expired?
  end

  protected

  def validate_scopes
    unless scopes.all? { |scope| Gitlab::Auth::AVAILABLE_SCOPES.include?(scope.to_sym) }
      errors.add :scopes, "can only contain available scopes"
    end
  end
end
