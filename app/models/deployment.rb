class Deployment < ActiveRecord::Base
  include InternalId

  belongs_to :project, required: true, validate: true
  belongs_to :environment, required: true, validate: true
  belongs_to :user
  belongs_to :deployable, polymorphic: true

  validates :sha, presence: true
  validates :ref, presence: true

  delegate :name, to: :environment, prefix: true

  def last?
    self == environment.last_deployment
  end

  def short_sha
    Commit.truncate_sha(sha)
  end

  def commit
    project.commit(sha)
  end

  def commit_title
    commit.try(:title)
  end

  def create_refs
    path = project.repository.path_to_repo

    project.repository.fetch_ref(path, ref, ref_path)
    project.repository.fetch_ref(path, ref, ref_path_head)
  end

  def manual_actions
    deployable.try(:other_actions)
  end

  private

  def ref_path
    environment.ref_path + id.to_s
  end

  def ref_path_head
    environment.ref_path + 'HEAD'
  end
end
