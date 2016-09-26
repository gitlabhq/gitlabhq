class Deployment < ActiveRecord::Base
  include InternalId

  belongs_to :project, required: true, validate: true
  belongs_to :environment, required: true, validate: true
  belongs_to :user
  belongs_to :deployable, polymorphic: true

  validates :sha, presence: true
  validates :ref, presence: true

  delegate :name, to: :environment, prefix: true

  after_save :create_ref

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

  def create_ref
    project.repository.fetch_ref(project.repository.path_to_repo, ref, ref_path)
  end

  def includes_commit?(commit)
    return false unless commit

    project.repository.is_ancestor?(commit.id, sha)
  end

  def manual_actions
    deployable.try(:other_actions)
  end

  private

  def ref_path
    "#{environment.ref_path}#{id}"
  end

  def update_merge_request_metrics!
    return unless environment.update_merge_request_metrics?

    merge_requests = project.merge_requests.
                     joins(:metrics).
                     where(target_branch: self.ref, merge_request_metrics: { first_deployed_to_production_at: nil }).
                     where("merge_request_metrics.merged_at <= ?", self.created_at)

    if previous_deployment
      merge_requests = merge_requests.where("merge_request_metrics.merged_at >= ?", previous_deployment.created_at)
    end

    # Need to use `map` instead of `select` because MySQL doesn't allow `SELECT`ing from the same table
    # that we're updating.
    merge_request_ids =
      if Gitlab::Database.postgresql?
        merge_requests.select(:id)
      elsif Gitlab::Database.mysql?
        merge_requests.map(&:id)
      end

    MergeRequest::Metrics.
      where(merge_request_id: merge_request_ids, first_deployed_to_production_at: nil).
      update_all(first_deployed_to_production_at: self.created_at)
  end

  def previous_deployment
    @previous_deployment ||=
      project.deployments.joins(:environment).
      where(environments: { name: self.environment.name }, ref: self.ref).
      where.not(id: self.id).
      take
  end
end
