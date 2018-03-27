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
  alias_attribute :pipeline_id, :commit_id

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
    script_failure: 1,
    api_failure: 2,
    stuck_or_timeout_failure: 3,
    runner_system_failure: 4,
    missing_dependency_failure: 5
  }

  ##
  # We still create some CommitStatuses outside of CreatePipelineService.
  #
  # These are pages deployments and external statuses.
  #
  before_create unless: :importing? do
    Ci::EnsureStageService.new(project, user).execute(self) do |stage|
      self.run_after_commit { StageUpdateWorker.perform_async(stage.id) }
    end
  end

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
      next unless commit_status.project
      next if transition.loopback?

      commit_status.run_after_commit do
        if pipeline_id
          if complete? || manual?
            PipelineProcessWorker.perform_async(pipeline_id)
          else
            PipelineUpdateWorker.perform_async(pipeline_id)
          end
        end

        StageUpdateWorker.perform_async(stage_id)
        ExpireJobCacheWorker.perform_async(id)
      end
    end

    after_transition any => :failed do |commit_status|
      next unless commit_status.project

      commit_status.run_after_commit do
        MergeRequests::AddTodoWhenBuildFailsService
          .new(project, nil).execute(self)
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
    name.to_s.gsub(%r{\d+[\.\s:/\\]+\d+\s*}, '').strip
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
