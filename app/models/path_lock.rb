class PathLock < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  validates :project, presence: true
  validates :user, presence: true
  validates :path, presence: true, uniqueness: { scope: :project }
  validate :path_unique_validation

  def downstream?(path)
    self.path.start_with?(path) && !exact?(path)
  end

  def upstream?(path)
    path.start_with?(self.path) && !exact?(path)
  end

  def exact?(path)
    self.path == path
  end

  private

  # This takes into account upstream and downstream locks
  def path_unique_validation
    return unless path
    return unless project

    # We don't use `project.find_path_lock` as we want to avoid memoizing the finder
    # in project instance
    existed_lock = Gitlab::PathLocksFinder.new(project).find(path, downstream: true)

    return unless existed_lock

    if existed_lock.downstream?(path)
      errors.add(:path, 'is invalid because there is downstream lock')
    elsif existed_lock.upstream?(path)
      errors.add(:path, 'is invalid because there is upstream lock')
    end
  end
end
