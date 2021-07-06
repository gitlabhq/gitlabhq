# frozen_string_literal: true

class DeployKey < Key
  include FromUnion
  include IgnorableColumns
  include PolicyActor

  has_many :deploy_keys_projects, inverse_of: :deploy_key, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :projects, through: :deploy_keys_projects
  has_many :protected_branch_push_access_levels, class_name: '::ProtectedBranch::PushAccessLevel'

  scope :in_projects, ->(projects) { joins(:deploy_keys_projects).where(deploy_keys_projects: { project_id: projects }) }
  scope :with_write_access, -> { joins(:deploy_keys_projects).merge(DeployKeysProject.with_write_access) }
  scope :are_public, -> { where(public: true) }
  scope :with_projects, -> { includes(deploy_keys_projects: { project: [:route, namespace: :route] }) }

  accepts_nested_attributes_for :deploy_keys_projects

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
    super || User.ghost
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

  def projects_with_write_access
    Project.with_route.where(id: deploy_keys_projects.with_write_access.select(:project_id))
  end

  def self.with_write_access_for_project(project, deploy_key: nil)
    query = in_projects(project).with_write_access
    query = query.where(id: deploy_key) if deploy_key

    query
  end
end
