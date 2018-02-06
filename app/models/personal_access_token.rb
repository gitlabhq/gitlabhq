class PersonalAccessToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  REDIS_EXPIRY_TIME = 3.minutes

  serialize :scopes, Array # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :user

  before_save :ensure_token

  scope :active, -> { where("revoked = false AND (expires_at >= NOW() OR expires_at IS NULL)") }
  scope :inactive, -> { where("revoked = true OR expires_at < NOW()") }
  scope :with_impersonation, -> { where(impersonation: true) }
  scope :without_impersonation, -> { where(impersonation: false) }

  validates :scopes, presence: true
  validate :validate_scopes

  after_initialize :set_default_scopes, if: :persisted?

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked? && !expired?
  end

  def self.redis_getdel(user_id)
    Gitlab::Redis::SharedState.with do |redis|
      token = redis.get(redis_shared_state_key(user_id))
      redis.del(redis_shared_state_key(user_id))
      token
    end
  end

  def self.redis_store!(user_id, token)
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(redis_shared_state_key(user_id), token, ex: REDIS_EXPIRY_TIME)
      token
    end
  end

  protected

  def validate_scopes
    unless revoked || scopes.all? { |scope| Gitlab::Auth.available_scopes.include?(scope.to_sym) }
      errors.add :scopes, "can only contain available scopes"
    end
  end

  def set_default_scopes
    self.scopes = Gitlab::Auth::DEFAULT_SCOPES if self.scopes.empty?
  end

  def self.redis_shared_state_key(user_id)
    "gitlab:personal_access_token:#{user_id}"
  end
end
