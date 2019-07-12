# frozen_string_literal: true

class DeployToken < ApplicationRecord
  include Expirable
  include TokenAuthenticatable
  include PolicyActor
  include Gitlab::Utils::StrongMemoize
  add_authentication_token_field :token, encrypted: :optional

  AVAILABLE_SCOPES = %i(read_repository read_registry).freeze
  GITLAB_DEPLOY_TOKEN_NAME = 'gitlab-deploy-token'.freeze

  default_value_for(:expires_at) { Forever.date }

  has_many :project_deploy_tokens, inverse_of: :deploy_token
  has_many :projects, through: :project_deploy_tokens

  validate :ensure_at_least_one_scope
  validates :username,
    length: { maximum: 255 },
    allow_nil: true,
    format: {
      with: /\A[a-zA-Z0-9\.\+_-]+\z/,
      message: "can contain only letters, digits, '_', '-', '+', and '.'"
    }

  before_save :ensure_token

  accepts_nested_attributes_for :project_deploy_tokens

  scope :active, -> { where("revoked = false AND expires_at >= NOW()") }

  def self.gitlab_deploy_token
    active.find_by(name: GITLAB_DEPLOY_TOKEN_NAME)
  end

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked && !expired?
  end

  def scopes
    AVAILABLE_SCOPES.select { |token_scope| read_attribute(token_scope) }
  end

  def username
    super || default_username
  end

  def has_access_to?(requested_project)
    active? && project == requested_project
  end

  # This is temporal. Currently we limit DeployToken
  # to a single project, later we're going to extend
  # that to be for multiple projects and namespaces.
  def project
    strong_memoize(:project) do
      projects.first
    end
  end

  def expires_at
    expires_at = read_attribute(:expires_at)
    expires_at != Forever.date ? expires_at : nil
  end

  def expires_at=(value)
    write_attribute(:expires_at, value.presence || Forever.date)
  end

  private

  def expired?
    return false unless expires_at

    expires_at < Date.today
  end

  def ensure_at_least_one_scope
    errors.add(:base, "Scopes can't be blank") unless read_repository || read_registry
  end

  def default_username
    "gitlab+deploy-token-#{id}" if persisted?
  end
end
