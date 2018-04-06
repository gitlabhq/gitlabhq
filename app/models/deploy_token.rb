class DeployToken < ActiveRecord::Base
  include Expirable
  include TokenAuthenticatable
  add_authentication_token_field :token

  AVAILABLE_SCOPES = %i(read_repository read_registry).freeze
  FUTURE_DATE = Date.new(3000 - 01 - 01)

  has_many :project_deploy_tokens, inverse_of: :deploy_token
  has_many :projects, through: :project_deploy_tokens

  validate :ensure_at_least_one_scope
  before_save :ensure_token

  accepts_nested_attributes_for :project_deploy_tokens

  scope :active, -> { where("revoked = false AND expires_at >= NOW()") }

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked
  end

  def scopes
    AVAILABLE_SCOPES.select { |token_scope| read_attribute(token_scope) }
  end

  def username
    "gitlab+deploy-token-#{id}"
  end

  def has_access_to?(requested_project)
    project == requested_project
  end

  # This is temporal. Currently we limit DeployToken
  # to a single project, later we're going to extend
  # that to be for multiple projects and namespaces.
  def project
    projects.first
  end

  private

  def ensure_at_least_one_scope
    errors.add(:base, "Scopes can't be blank") unless read_repository || read_registry
  end
end
