class DeployToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  AVAILABLE_SCOPES = %w(read_repository read_registry).freeze

  serialize :scopes, Array # rubocop:disable Cop/ActiveRecordSerialize

  validates :scopes, presence: true
  validates :project, presence: true

  belongs_to :project

  before_save :ensure_token

  scope :active, -> { where("revoked = false AND (expires_at >= NOW() OR expires_at IS NULL)") }

  def revoke!
    update!(revoked: true)
  end

  def redis_shared_state_key(user_id)
    "gitlab:deploy_token:#{project_id}:#{user_id}"
  end

  def active?
    !revoked
  end

  def username
    "gitlab+deploy-token-#{id}"
  end

  def has_access_to?(project)
    self.project == project
  end
end
