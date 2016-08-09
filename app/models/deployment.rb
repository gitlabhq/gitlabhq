class Deployment < ActiveRecord::Base
  include InternalId

  belongs_to :project, required: true, validate: true
  belongs_to :environment, required: true, validate: true
  belongs_to :user
  belongs_to :deployable, polymorphic: true

  validates :sha, presence: true
  validates :ref, presence: true

  delegate :name, to: :environment, prefix: true

  after_save :keep_around_commit

  def commit
    project.commit(sha)
  end

  def commit_title
    commit.try(:title)
  end

  def short_sha
    Commit.truncate_sha(sha)
  end

  def last?
    self == environment.last_deployment
  end

  def keep_around_commit
    project.repository.keep_around(self.sha)
  end

  def manual_actions
    deployable.try(:other_actions)
  end

  def includes_commit?(commit)
    return false unless commit

    project.repository.is_ancestor?(commit.id, sha)
  end
end
