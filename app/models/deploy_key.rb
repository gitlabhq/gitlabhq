# frozen_string_literal: true

class DeployKey < Key
  include FromUnion
  include PolicyActor
  include Presentable
  include Gitlab::SQL::Pattern

  self.allow_legacy_sti_class = true

  has_many :deploy_keys_projects, inverse_of: :deploy_key, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :projects, through: :deploy_keys_projects

  has_many :deploy_keys_projects_with_write_access, -> { with_write_access }, class_name: "DeployKeysProject", inverse_of: :deploy_key
  has_many :deploy_keys_projects_with_readonly_access, -> { with_readonly_access }, class_name: "DeployKeysProject", inverse_of: :deploy_key
  has_many :projects_with_write_access, -> { includes(:route) }, class_name: 'Project', through: :deploy_keys_projects_with_write_access, source: :project
  has_many :projects_with_readonly_access, -> { includes(:route) }, class_name: 'Project', through: :deploy_keys_projects_with_readonly_access, source: :project
  has_many :protected_branch_push_access_levels, class_name: '::ProtectedBranch::PushAccessLevel', inverse_of: :deploy_key
  has_many :protected_tag_create_access_levels, class_name: '::ProtectedTag::CreateAccessLevel', inverse_of: :deploy_key

  scope :in_projects, ->(projects) { joins(:deploy_keys_projects).where(deploy_keys_projects: { project_id: projects }) }
  scope :with_write_access, -> { joins(:deploy_keys_projects).merge(DeployKeysProject.with_write_access) }
  scope :with_readonly_access, -> { joins(:deploy_keys_projects).merge(DeployKeysProject.with_readonly_access) }
  scope :are_public, -> { where(public: true) }
  scope :with_projects, -> { includes(deploy_keys_projects: { project: [:route, { namespace: :route }, :fork_network] }) }
  scope :including_projects_with_write_access, -> { includes(:projects_with_write_access) }
  scope :including_projects_with_readonly_access, -> { includes(:projects_with_readonly_access) }
  scope :not_in, ->(keys) { where.not(id: keys.select(:id)) }

  scope :search_by_title, ->(term) {
    sanitized_term = sanitize_sql_like(term.downcase)
    where("title ILIKE :term", term: "%#{sanitized_term}%")
  }

  scope :search_by_key, ->(term) {
    sanitized_term = sanitize_sql_like(term)
    where("encode(fingerprint_sha256, 'base64') ILIKE :term", term: "%#{sanitized_term}%")
  }

  accepts_nested_attributes_for :deploy_keys_projects, reject_if: :reject_deploy_keys_projects?

  def private?
    !public?
  end

  def orphaned?
    self.deploy_keys_projects.empty?
  end

  def almost_orphaned?
    self.deploy_keys_projects.size == 1
  end

  def destroyed_when_orphaned?
    self.private?
  end

  def user
    super || Users::Internal.ghost
  end

  def audit_details
    title
  end

  def has_access_to?(project)
    deploy_keys_project_for(project).present?
  end

  def can_push_to?(project)
    !!deploy_keys_project_for(project)&.can_push?
  end

  def deploy_keys_project_for(project)
    if association(:deploy_keys_projects).loaded?
      deploy_keys_projects.find { |dkp| dkp.project_id.eql?(project&.id) }
    else
      deploy_keys_projects.find_by(project: project)
    end
  end

  def self.with_write_access_for_project(project, deploy_key: nil)
    query = in_projects(project).with_write_access
    query = query.where(id: deploy_key) if deploy_key

    query
  end

  # This is used for the internal logic of AuditEvents::BuildService.
  def impersonated?
    false
  end

  private

  def reject_deploy_keys_projects?
    !self.valid?
  end

  def self.search(term, field = nil)
    return all unless term.present?

    case field&.to_s
    when 'title'
      search_by_title(term)
    when 'key'
      search_by_key(term)
    else
      search_by_title(term).or(search_by_key(term))
    end
  end
end
