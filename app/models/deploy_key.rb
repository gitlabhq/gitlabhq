class DeployKey < Key
  has_many :deploy_keys_projects, dependent: :destroy
  has_many :projects, through: :deploy_keys_projects

  scope :in_projects, ->(projects) { joins(:deploy_keys_projects).where('deploy_keys_projects.project_id in (?)', projects) }
  scope :are_public,  -> { where(public: true) }

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
end
