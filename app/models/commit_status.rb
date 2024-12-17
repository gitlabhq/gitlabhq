# frozen_string_literal: true

class CommitStatus < Ci::ApplicationRecord
  include Ci::Partitionable
  include Ci::HasStatus
  include Importable
  include AfterCommitQueue
  include Presentable
  include BulkInsertableAssociations
  include TaggableQueries

  ignore_columns :stage, remove_with: '17.10', remove_after: '2025-03-14'

  self.table_name = :p_ci_builds
  self.sequence_name = :ci_builds_id_seq
  self.primary_key = :id

  query_constraints :id, :partition_id
  partitionable scope: :pipeline, partitioned: true

  belongs_to :user
  belongs_to :project
  belongs_to :pipeline,
    ->(build) { in_partition(build) },
    class_name: 'Ci::Pipeline',
    foreign_key: :commit_id,
    inverse_of: :statuses,
    partition_foreign_key: :partition_id
  belongs_to :auto_canceled_by, class_name: 'Ci::Pipeline', inverse_of: :auto_canceled_jobs
  belongs_to :ci_stage,
    ->(build) { in_partition(build) },
    class_name: 'Ci::Stage',
    foreign_key: :stage_id,
    partition_foreign_key: :partition_id

  has_many :needs, class_name: 'Ci::BuildNeed', foreign_key: :build_id, inverse_of: :build

  attribute :retried, default: false

  enum scheduling_type: { stage: 0, dag: 1 }, _prefix: true
  # We use `Enums::Ci::CommitStatus.failure_reasons` here so that EE can more easily
  # extend this `Hash` with new values.
  enum failure_reason: Enums::Ci::CommitStatus.failure_reasons

  delegate :commit, to: :pipeline
  delegate :sha, :short_sha, :before_sha, to: :pipeline

  validates :pipeline, presence: true, unless: :importing?
  validates :name, presence: true, unless: :importing?
  validates :ci_stage, presence: true, on: :create, unless: :importing?
  validates :ref, :target_url, :description, length: { maximum: 255 }
  validates :project, presence: true

  alias_attribute :author, :user
  alias_attribute :pipeline_id, :commit_id

  scope :failed_but_allowed, -> do
    where(allow_failure: true, status: [:failed, :canceled])
  end

  scope :order_id_desc, -> { order(id: :desc) }

  scope :latest, -> { where(retried: [false, nil]) }
  scope :retried, -> { where(retried: true) }
  scope :ordered, -> { order(:name) }
  scope :ordered_by_stage, -> { order(stage_idx: :asc) }
  scope :latest_ordered, -> { latest.ordered.includes(project: :namespace) }
  scope :retried_ordered, -> { retried.order(name: :asc, id: :desc).includes(project: :namespace) }
  scope :ordered_by_pipeline, -> { order(pipeline_id: :asc) }
  scope :before_stage, ->(index) { where('stage_idx < ?', index) }
  scope :for_stage, ->(index) { where(stage_idx: index) }
  scope :after_stage, ->(index) { where('stage_idx > ?', index) }
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :for_ref, ->(ref) { where(ref: ref) }
  scope :by_name, ->(name) { where(name: name) }
  scope :in_pipelines, ->(pipelines) { where(pipeline: pipelines) }
  scope :with_pipeline, -> { joins(:pipeline) }
  scope :updated_at_before, ->(date) { where("#{quoted_table_name}.updated_at < ?", date) }
  scope :created_at_before, ->(date) { where("#{quoted_table_name}.created_at < ?", date) }
  scope :scheduled_at_before, ->(date) {
    where("#{quoted_table_name}.scheduled_at IS NOT NULL AND #{quoted_table_name}.scheduled_at < ?", date)
  }
  scope :with_when_executed, ->(when_executed) { where(when: when_executed) }
  scope :with_type, ->(type) { where(type: type) }

  # The scope applies `pluck` to split the queries. Use with care.
  scope :for_project_paths, ->(paths) do
    # Pluck is used to split this query. Splitting the query is required for database decomposition for `ci_*` tables.
    # https://docs.gitlab.com/ee/development/database/transaction_guidelines.html#database-decomposition-and-sharding
    project_ids = Project.where_full_path_in(Array(paths), preload_routes: false).pluck(:id)

    for_project(project_ids)
  end

  scope :with_preloads, -> do
    preload(:project, :user)
  end

  scope :with_project_preload, -> do
    preload(project: :namespace)
  end

  scope :scoped_pipeline, -> do
    where(arel_table[:commit_id].eq(Ci::Pipeline.arel_table[:id]))
    .where(arel_table[:partition_id].eq(Ci::Pipeline.arel_table[:partition_id]))
  end

  scope :match_id_and_lock_version, ->(items) do
    # it expects that items are an array of attributes to match
    # each hash needs to have `id` and `lock_version`
    or_conditions = items.inject(none) do |relation, item|
      match = CommitStatus.default_scoped.where(item.slice(:id, :lock_version))

      relation.or(match)
    end

    merge(or_conditions)
  end

  before_save if: :status_changed?, unless: :importing? do
    # we mark `processed` as always changed:
    # another process might change its value and our object
    # will not be refreshed to pick the change
    self.processed_will_change!

    if latest?
      self.processed = false # force refresh of all dependent ones
    elsif retried?
      self.processed = true # retried are considered to be already processed
    end
  end

  state_machine :status do
    event :process do
      transition [:skipped, :manual] => :created
    end

    event :enqueue do
      # A CommitStatus will never have prerequisites, but this event
      # is shared by Ci::Build, which cannot progress unless prerequisites
      # are satisfied.
      transition [:created, :skipped, :manual, :scheduled] => :pending, if: :all_met_to_become_pending?
    end

    event :run do
      transition pending: :running
    end

    event :skip do
      transition [:created, :waiting_for_resource, :preparing, :pending] => :skipped
    end

    event :drop do
      transition canceling: :canceled # runner returns success/failed
      transition [
        :created,
        :waiting_for_resource,
        :preparing,
        :waiting_for_callback,
        :pending,
        :running,
        :manual,
        :scheduled
      ] => :failed
    end

    event :success do
      transition canceling: :canceled # runner returns success/failed
      transition [:created, :waiting_for_resource, :preparing, :waiting_for_callback, :pending, :running] => :success
    end

    event :cancel do
      transition running: :canceling, if: :supports_canceling?
      transition CANCELABLE_STATUSES.map(&:to_sym) + [:manual] => :canceled
    end

    before_transition [
      :created,
      :waiting_for_resource,
      :preparing,
      :skipped,
      :manual,
      :scheduled
    ] => :pending do |commit_status|
      commit_status.queued_at = Time.current
    end

    before_transition [:created, :preparing, :pending] => :running do |commit_status|
      commit_status.started_at = Time.current
    end

    before_transition any => [:success, :failed, :canceled] do |commit_status|
      commit_status.finished_at = Time.current
    end

    before_transition any => :failed do |commit_status, transition|
      reason = ::Gitlab::Ci::Build::Status::Reason
        .fabricate(commit_status, transition.args.first)

      commit_status.failure_reason = reason.failure_reason_enum
      commit_status.allow_failure = true if reason.force_allow_failure?
      # Windows exit codes can reach a max value of 32-bit unsigned integer
      # We only allow a smallint for exit_code in the db, hence the added limit of 32767
      commit_status.exit_code = reason.exit_code
    end

    before_transition [:skipped, :manual] => :created do |commit_status, transition|
      transition.args.first.try do |user|
        commit_status.user = user
      end
    end

    after_transition do |commit_status, transition|
      next if transition.loopback?
      next if commit_status.processed?
      next unless commit_status.project

      last_arg = transition.args.last
      transition_options = last_arg.is_a?(Hash) && last_arg.extractable_options? ? last_arg : {}

      commit_status.run_after_commit do
        PipelineProcessWorker.perform_async(pipeline_id) unless transition_options[:skip_pipeline_processing]

        expire_etag_cache!
      end
    end

    after_transition any => :failed do |commit_status|
      commit_status.run_after_commit do
        ::Gitlab::Ci::Pipeline::Metrics.job_failure_reason_counter.increment(reason: commit_status.failure_reason)
      end
    end
  end

  def self.names
    select(:name)
  end

  def self.update_as_processed!
    # Marks items as processed
    # we do not increase `lock_version`, as we are the one
    # holding given lock_version (Optimisitc Locking)
    update_all(processed: true)
  end

  def self.locking_enabled?
    false
  end

  def locking_enabled?
    will_save_change_to_status?
  end

  def group_name
    # [\b\s:] -> whitespace or column
    # (\[.*\])|(\d+[\s:\/\\]+\d+) -> variables/matrix or parallel-jobs numbers
    # {1,3} -> number of times that matches the variables/matrix or parallel-jobs numbers
    #          we limit this to 3 because of possible abuse
    regex = %r{([\b\s:]+((\[.*\])|(\d+[\s:\/\\]+\d+))){1,3}\s*\z}

    name.to_s.sub(regex, '').strip
  end

  def supports_canceling?
    false
  end

  # Time spent running.
  def duration
    calculate_duration(started_at, finished_at)
  end

  # Time spent in the pending state.
  def queued_duration
    calculate_duration(queued_at, started_at)
  end

  def latest?
    !retried?
  end

  def playable?
    false
  end

  def retryable?
    false
  end

  def cancelable?
    false
  end

  def archived?
    false
  end

  def stuck?
    false
  end

  def has_trace?
    false
  end

  def all_met_to_become_pending?
    true
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
      /\d+/.match?(v) ? v.to_i : v
    end
  end

  def recoverable?
    failed? && !unrecoverable_failure?
  end

  def update_older_statuses_retried!
    pipeline
      .statuses
      .latest
      .where(name: name)
      .where.not(id: id)
      .update_all(retried: true, processed: true)
  end

  def expire_etag_cache!
    job_path = Gitlab::Routing.url_helpers.project_build_path(project, id, format: :json)

    Gitlab::EtagCaching::Store.new.touch(job_path)
  end

  def stage_name
    ci_stage&.name
  end

  # TODO: Temporary technical debt so we can ignore `stage`: https://gitlab.com/gitlab-org/gitlab/-/issues/507579
  alias_method :stage, :stage_name

  # Handled only by ci_build
  def exit_code=(value); end

  # For AiAction
  def to_ability_name
    'build'
  end

  # For AiAction
  def resource_parent
    project
  end

  private

  def unrecoverable_failure?
    script_failure? || missing_dependency_failure? || archived_failure? || scheduler_failure? || data_integrity_failure?
  end
end
