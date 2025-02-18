# frozen_string_literal: true

class DeployToken < ApplicationRecord
  include Expirable
  include TokenAuthenticatable
  include PolicyActor
  include Gitlab::Utils::StrongMemoize

  AVAILABLE_SCOPES = %i[read_repository read_registry write_registry
    read_package_registry write_package_registry
    read_virtual_registry write_virtual_registry].freeze
  GITLAB_DEPLOY_TOKEN_NAME = 'gitlab-deploy-token'
  DEPLOY_TOKEN_PREFIX = 'gldt-'

  add_authentication_token_field :token, encrypted: :required, format_with_prefix: :prefix_for_deploy_token

  attribute :expires_at, default: -> { Forever.date }

  # Do NOT use this `user` for the authentication/authorization of the deploy tokens.
  # It's for the auditing purpose on Credential Inventory, only.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/353467#note_859774246 for more information.
  belongs_to :user, foreign_key: :creator_id, optional: true

  has_many :project_deploy_tokens, inverse_of: :deploy_token
  has_many :projects, through: :project_deploy_tokens

  has_many :group_deploy_tokens, inverse_of: :deploy_token
  has_many :groups, through: :group_deploy_tokens

  validate :no_groups, unless: :group_type?
  validate :no_projects, unless: :project_type?
  validate :ensure_at_least_one_scope
  validates :username,
    length: { maximum: 255 },
    allow_nil: true,
    format: {
      with: /\A[a-zA-Z0-9\.\+_-]+\z/,
      message: "can contain only letters, digits, '_', '-', '+', and '.'"
    }

  validates :expires_at, iso8601_date: true, on: :create
  validates :deploy_token_type, presence: true
  enum deploy_token_type: {
    group_type: 1,
    project_type: 2
  }

  before_save :ensure_token

  accepts_nested_attributes_for :project_deploy_tokens

  scope :active, -> { where("revoked = false AND expires_at >= NOW()") }

  def self.gitlab_deploy_token
    active.find_by(name: GITLAB_DEPLOY_TOKEN_NAME)
  end

  def valid_for_dependency_proxy?
    group_type? &&
      active? &&
      (Gitlab::Auth::REGISTRY_SCOPES & scopes).size == Gitlab::Auth::REGISTRY_SCOPES.size
  end

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked && !expired?
  end

  def deactivated?
    !active?
  end

  def scopes
    AVAILABLE_SCOPES.select { |token_scope| read_attribute(token_scope) }
  end

  def username
    super || default_username
  end

  def has_access_to?(requested_project)
    return false unless active?
    return false unless holder

    holder.has_access_to?(requested_project)
  end

  def has_access_to_group?(requested_group)
    return false unless active?
    return false unless group_type?
    return false unless holder

    holder.has_access_to_group?(requested_group)
  end

  # This is temporal. Currently we limit DeployToken
  # to a single project or group, later we're going to
  # extend that to be for multiple projects and namespaces.
  def project
    strong_memoize(:project) do
      projects.first
    end
  end

  def group
    strong_memoize(:group) do
      groups.first
    end
  end

  def accessible_projects
    if project_type?
      projects
    elsif group_type?
      group.all_projects
    end
  end

  def holder
    strong_memoize(:holder) do
      if project_type?
        project_deploy_tokens.first
      elsif group_type?
        group_deploy_tokens.first
      end
    end
  end

  def impersonated?
    false
  end

  def expires_at
    expires_at = read_attribute(:expires_at)
    expires_at != Forever.date ? expires_at : nil
  end

  def expires_at=(value)
    write_attribute(:expires_at, value.presence || Forever.date)
  end

  def prefix_for_deploy_token
    DEPLOY_TOKEN_PREFIX
  end

  private

  def expired?
    return false unless expires_at

    expires_at < Date.today
  end

  def ensure_at_least_one_scope
    errors.add(:base, _("Scopes can't be blank")) unless scopes.any?
  end

  def default_username
    "gitlab+deploy-token-#{id}" if persisted?
  end

  def no_groups
    errors.add(:deploy_token, 'cannot have groups assigned') if group_deploy_tokens.any?
  end

  def no_projects
    errors.add(:deploy_token, 'cannot have projects assigned') if project_deploy_tokens.any?
  end
end
