class DeployKey < Key
  has_many :deploy_keys_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
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

  def has_access_to?(project)
    projects.include?(project)
  end

  def can_push_to?(project)
    can_push? && has_access_to?(project)
  end

  private

  # we don't want to notify the user for deploy keys
  def notify_user
  end
end
