class DeployKey < Key
  include IgnorableColumn

  has_many :deploy_keys_projects, inverse_of: :deploy_key, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :projects, -> { auto_include(false) }, through: :deploy_keys_projects

  scope :in_projects, ->(projects) { joins(:deploy_keys_projects).where('deploy_keys_projects.project_id in (?)', projects) }
  scope :are_public,  -> { where(public: true) }

  ignore_column :can_push

  accepts_nested_attributes_for :deploy_keys_projects

  def private?
    !public?
  end

  def orphaned?
    self.deploy_keys_projects.length == 0
  end

  def almost_orphaned?
    self.deploy_keys_projects.length == 1
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
    deploy_keys_projects.find_by(project: project)
  end

  def projects_with_write_access
    Project.preload(:route).where(id: deploy_keys_projects.with_write_access.select(:project_id))
  end
end
