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


  def update_merge_request_metrics
    if environment.update_merge_request_metrics?
      query = project.merge_requests.
              joins(:metrics).
              where(target_branch: self.ref, merge_request_metrics: { first_deployed_to_production_at: nil })

      merge_requests =
        if previous_deployment
          query.where("merge_request_metrics.merged_at <= ? AND merge_request_metrics.merged_at >= ?",
                      self.created_at,
                      previous_deployment.created_at)
        else
          query.where("merge_request_metrics.merged_at <= ?", self.created_at)
        end

      # Need to use `map` instead of `select` because MySQL doesn't allow `SELECT`ing from the same table
      # that we're updating.
      MergeRequest::Metrics.where(merge_request_id: merge_requests.map(&:id), first_deployed_to_production_at: nil).
        update_all(first_deployed_to_production_at: self.created_at)
    end
  end

  def previous_deployment
    @previous_deployment ||=
      project.deployments.joins(:environment).
      where(environments: { name: self.environment.name }, ref: self.ref).
      where.not(id: self.id).
      take
  end
end
