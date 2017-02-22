class CommitStatus < ActiveRecord::Base
  include HasStatus
  include Importable
  include AfterCommitQueue

  self.table_name = 'ci_builds'

  belongs_to :project, foreign_key: :gl_project_id
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :commit_id
  belongs_to :user

  delegate :commit, to: :pipeline
  delegate :sha, :short_sha, to: :pipeline

  validates :pipeline, presence: true, unless: :importing?

  validates :name, presence: true

  alias_attribute :author, :user

  scope :latest, -> do
    max_id = unscope(:select).select("max(#{quoted_table_name}.id)")

    where(id: max_id.group(:name, :commit_id))
  end

  scope :failed_but_allowed, -> do
    where(allow_failure: true, status: [:failed, :canceled])
  end

  scope :exclude_ignored, -> do
    # We want to ignore failed_but_allowed jobs
    where("allow_failure = ? OR status IN (?)",
      false, all_state_names - [:failed, :canceled])
  end

  scope :retried, -> { where.not(id: latest) }
  scope :ordered, -> { order(:name) }
  scope :latest_ordered, -> { latest.ordered.includes(project: :namespace) }
  scope :retried_ordered, -> { retried.ordered.includes(project: :namespace) }
  scope :after_stage, -> (index) { where('stage_idx > ?', index) }

  state_machine :status do
    event :enqueue do
      transition [:created, :skipped] => :pending
    end

    event :process do
      transition skipped: :created
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
      transition [:created, :pending, :running] => :canceled
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

    after_transition do |commit_status, transition|
      next if transition.loopback?

      commit_status.run_after_commit do
        pipeline.try do |pipeline|
          if complete?
            PipelineProcessWorker.perform_async(pipeline.id)
          else
            PipelineUpdateWorker.perform_async(pipeline.id)
          end
        end
      end
    end

    after_transition any => :failed do |commit_status|
      commit_status.run_after_commit do
        MergeRequests::AddTodoWhenBuildFailsService
          .new(pipeline.project, nil).execute(self)
      end
    end
  end

  def before_sha
    pipeline.before_sha || Gitlab::Git::BLANK_SHA
  end

  def group_name
    name.gsub(/\d+[\s:\/\\]+\d+\s*/, '').strip
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

  def stuck?
    false
  end

  def has_trace?
    false
  end

  def detailed_status(current_user)
    Gitlab::Ci::Status::Factory
      .new(self, current_user)
      .fabricate!
  end

  def sortable_name
    name.split(/(\d+)/).map do |v|
      v =~ /\d+/ ? v.to_i : v
    end
  end
end
