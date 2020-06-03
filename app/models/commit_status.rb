# frozen_string_literal: true

class CommitStatus < ApplicationRecord
  include HasStatus
  include Importable
  include AfterCommitQueue
  include Presentable
  include EnumWithNil

  self.table_name = 'ci_builds'

  belongs_to :user
  belongs_to :project
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :commit_id
  belongs_to :auto_canceled_by, class_name: 'Ci::Pipeline'

  has_many :needs, class_name: 'Ci::BuildNeed', foreign_key: :build_id, inverse_of: :build

  enum scheduling_type: { stage: 0, dag: 1 }, _prefix: true

  delegate :commit, to: :pipeline
  delegate :sha, :short_sha, :before_sha, to: :pipeline

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
  scope :ordered_by_stage, -> { order(stage_idx: :asc) }
  scope :latest_ordered, -> { latest.ordered.includes(project: :namespace) }
  scope :retried_ordered, -> { retried.ordered.includes(project: :namespace) }
  scope :before_stage, -> (index) { where('stage_idx < ?', index) }
  scope :for_stage, -> (index) { where(stage_idx: index) }
  scope :after_stage, -> (index) { where('stage_idx > ?', index) }
  scope :for_ids, -> (ids) { where(id: ids) }
  scope :for_ref, -> (ref) { where(ref: ref) }
  scope :by_name, -> (name) { where(name: name) }

  scope :for_project_paths, -> (paths) do
    where(project: Project.where_full_path_in(Array(paths)))
  end

  scope :with_preloads, -> do
    preload(:project, :user)
  end

  scope :with_project_preload, -> do
    preload(project: :namespace)
  end

  scope :match_id_and_lock_version, -> (items) do
    # it expects that items are an array of attributes to match
    # each hash needs to have `id` and `lock_version`
    or_conditions = items.inject(none) do |relation, item|
      match = CommitStatus.default_scoped.where(item.slice(:id, :lock_version))

      relation.or(match)
    end

    merge(or_conditions)
  end

  # We use `CommitStatusEnums.failure_reasons` here so that EE can more easily
  # extend this `Hash` with new values.
  enum_with_nil failure_reason: ::CommitStatusEnums.failure_reasons

  ##
  # We still create some CommitStatuses outside of CreatePipelineService.
  #
  # These are pages deployments and external statuses.
  #
  before_create unless: :importing? do
    # rubocop: disable CodeReuse/ServiceClass
    Ci::EnsureStageService.new(project, user).execute(self) do |stage|
      self.run_after_commit { StageUpdateWorker.perform_async(stage.id) }
    end
    # rubocop: enable CodeReuse/ServiceClass
  end

  before_save if: :status_changed?, unless: :importing? do
    # we mark `processed` as always changed:
    # another process might change its value and our object
    # will not be refreshed to pick the change
    self.processed_will_change!

    if Feature.disabled?(:ci_atomic_processing, project)
      self.processed = nil
    elsif latest?
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
      transition [:created, :waiting_for_resource, :preparing, :pending, :running, :scheduled] => :failed
    end

    event :success do
      transition [:created, :waiting_for_resource, :preparing, :pending, :running] => :success
    end

    event :cancel do
      transition [:created, :waiting_for_resource, :preparing, :pending, :running, :manual, :scheduled] => :canceled
    end

    before_transition [:created, :waiting_for_resource, :preparing, :skipped, :manual, :scheduled] => :pending do |commit_status|
      commit_status.queued_at = Time.current
    end

    before_transition [:created, :preparing, :pending] => :running do |commit_status|
      commit_status.started_at = Time.current
    end

    before_transition any => [:success, :failed, :canceled] do |commit_status|
      commit_status.finished_at = Time.current
    end

    before_transition any => :failed do |commit_status, transition|
      failure_reason = transition.args.first
      commit_status.failure_reason = CommitStatus.failure_reasons[failure_reason]
    end

    after_transition do |commit_status, transition|
      next if transition.loopback?
      next if commit_status.processed?
      next unless commit_status.project

      commit_status.run_after_commit do
        schedule_stage_and_pipeline_update

        ExpireJobCacheWorker.perform_async(id)
      end
    end

    after_transition any => :failed do |commit_status|
      next unless commit_status.project

      # rubocop: disable CodeReuse/ServiceClass
      commit_status.run_after_commit do
        MergeRequests::AddTodoWhenBuildFailsService
          .new(project, nil).execute(self)
      end
      # rubocop: enable CodeReuse/ServiceClass
    end
  end

  def self.names
    select(:name)
  end

  def self.status_for_prior_stages(index, project:)
    before_stage(index).latest.slow_composite_status(project: project) || 'success'
  end

  def self.status_for_names(names, project:)
    where(name: names).latest.slow_composite_status(project: project) || 'success'
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
    name.to_s.gsub(%r{\d+[\s:/\\]+\d+\s*}, '').strip
  end

  def failed_but_allowed?
    allow_failure? && (failed? || canceled?)
  end

  def duration
    calculate_duration
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
    !any_unmet_prerequisites? && !requires_resource?
  end

  def any_unmet_prerequisites?
    false
  end

  def requires_resource?
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

  def recoverable?
    failed? && !unrecoverable_failure?
  end

  private

  def unrecoverable_failure?
    script_failure? || missing_dependency_failure? || archived_failure? || scheduler_failure? || data_integrity_failure?
  end

  def schedule_stage_and_pipeline_update
    if Feature.enabled?(:ci_atomic_processing, project)
      # Atomic Processing requires only single Worker
      PipelineProcessWorker.perform_async(pipeline_id, [id])
    else
      if complete? || manual?
        PipelineProcessWorker.perform_async(pipeline_id, [id])
      else
        PipelineUpdateWorker.perform_async(pipeline_id)
      end

      StageUpdateWorker.perform_async(stage_id)
    end
  end
end

CommitStatus.prepend_if_ee('::EE::CommitStatus')
