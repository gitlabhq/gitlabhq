class CommitStatus < ActiveRecord::Base
  include HasStatus
  include Importable
  include AfterCommitQueue

  self.table_name = 'ci_builds'

  belongs_to :user
  belongs_to :project
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :commit_id
  belongs_to :auto_canceled_by, class_name: 'Ci::Pipeline'

  delegate :commit, to: :pipeline
  delegate :sha, :short_sha, to: :pipeline

  validates :pipeline, presence: true, unless: :importing?

  validates :name, presence: true, unless: :importing?

  alias_attribute :author, :user

  scope :failed_but_allowed, -> do
    where(allow_failure: true, status: [:failed, :canceled])
  end

  scope :exclude_ignored, -> do
    # We want to ignore failed but allowed to fail jobs.
    #
    # TODO, we also skip ignored optional manual actions.
    where("allow_failure = ? OR status IN (?)",
      false, all_state_names - [:failed, :canceled, :manual])
  end

  scope :latest, -> { where(retried: [false, nil]) }
  scope :retried, -> { where(retried: true) }
  scope :ordered, -> { order(:name) }
  scope :latest_ordered, -> { latest.ordered.includes(project: :namespace) }
  scope :retried_ordered, -> { retried.ordered.includes(project: :namespace) }
  scope :after_stage, -> (index) { where('stage_idx > ?', index) }

  enum failure_reason: {
    unknown_failure: nil,
    job_failure: 1,
    api_failure: 2,
    stuck_or_timeout_failure: 3
  }

  state_machine :status do
    event :process do
      transition [:skipped, :manual] => :created
    end

    event :enqueue do
      transition [:created, :skipped, :manual] => :pending
    end

    event :run do
      transition pending: :running
    end

    event :skip do
      transition [:created, :pending] => :skipped
    end

    event :drop do
      transition [:created, :pending, :running] => :failed
    end

    event :success do
      transition [:created, :pending, :running] => :success
    end

    event :cancel do
      transition [:created, :pending, :running, :manual] => :canceled
    end

    before_transition created: [:pending, :running] do |commit_status|
      commit_status.queued_at = Time.now
    end

    before_transition [:created, :pending] => :running do |commit_status|
      commit_status.started_at = Time.now
    end

    before_transition any => [:success, :failed, :canceled] do |commit_status|
      commit_status.finished_at = Time.now
    end

    before_transition any => :failed do |commit_status, transition|
      failure_reason = transition.args.first
      commit_status.failure_reason = failure_reason
    end

    after_transition do |commit_status, transition|
      next if transition.loopback?

      commit_status.run_after_commit do
        if pipeline
          if complete? || manual?
            PipelineProcessWorker.perform_async(pipeline.id)
          else
            PipelineUpdateWorker.perform_async(pipeline.id)
          end
        end

        StageUpdateWorker.perform_async(commit_status.stage_id)
        ExpireJobCacheWorker.perform_async(commit_status.id)
      end
    end

    after_transition any => :failed do |commit_status|
      commit_status.run_after_commit do
        MergeRequests::AddTodoWhenBuildFailsService
          .new(pipeline.project, nil).execute(self)
      end
    end
  end

  def locking_enabled?
    status_changed?
  end

  def before_sha
    pipeline.before_sha || Gitlab::Git::BLANK_SHA
  end

  def group_name
    name.to_s.gsub(/\d+[\s:\/\\]+\d+\s*/, '').strip
  end

  def failed_but_allowed?
    allow_failure? && (failed? || canceled?)
  end

  def duration
    calculate_duration
  end

  def playable?
    false
  end

  # To be overriden when inherrited from
  def retryable?
    false
  end

  # To be overriden when inherrited from
  def cancelable?
    false
  end

  def stuck?
    false
  end

  def has_trace?
    false
  end

  def auto_canceled?
    canceled? && auto_canceled_by_id?
  end

  def detailed_status(current_user)
    Gitlab::Ci::Status::Factory
      .new(self, current_user)
      .fabricate!
  end

  def sortable_name
    name.to_s.split(/(\d+)/).map do |v|
      v =~ /\d+/ ? v.to_i : v
    end
  end
end
