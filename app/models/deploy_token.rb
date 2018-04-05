class DeployToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  AVAILABLE_SCOPES = %i(read_repository read_registry).freeze

  has_many :project_deploy_tokens, inverse_of: :deploy_token
  has_many :projects, through: :project_deploy_tokens

  validate :ensure_at_least_one_scope
  before_save :ensure_token

  accepts_nested_attributes_for :project_deploy_tokens

  scope :active, -> { where("revoked = false AND (expires_at >= NOW() OR expires_at IS NULL)") }
  scope :read_repository, -> { where(read_repository: true) }
  scope :read_registry, -> { where(read_registry: true) }

  def self.redis_shared_state_key(user_id)
    "gitlab:deploy_token:user_#{user_id}"
  end

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked
  end

  def scopes
    AVAILABLE_SCOPES.select { |token_scope| send("#{token_scope}") }  # rubocop:disable GitlabSecurity/PublicSend
  end

  def username
    "gitlab+deploy-token-#{id}"
  end

  def has_access_to?(requested_project)
    self.projects.first == requested_project
  end

  def project
    projects.first
  end

  private

  def ensure_at_least_one_scope
    errors.add(:base, "Scopes can't be blank") unless read_repository || read_registry
  end
end
