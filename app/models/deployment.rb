class Deployment < ActiveRecord::Base
  include InternalId

  belongs_to :project
  belongs_to :environment
  belongs_to :user
  belongs_to :deployable, polymorphic: true

  validates_presence_of :sha
  validates_presence_of :ref
  validates_associated :project
  validates_associated :environment

  delegate :name, to: :environment, prefix: true

  def commit
    project.commit(sha)
  end

  def commit_title
    commit.try(:title)
  end

  def short_sha
    Commit::truncate_sha(sha)
  end

  def last?
    self == environment.last_deployment
  end
end
