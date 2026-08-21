# frozen_string_literal: true

class ProjectExportJob < ApplicationRecord
  include EachBatch
  include AfterCommitQueue
  extend Gitlab::ExclusiveLeaseHelpers

  EXPIRES_IN = 7.days
  FIND_OR_CREATE_LOCK_TTL = 10.seconds
  FIND_OR_CREATE_LOCK_RETRIES = 10
  FIND_OR_CREATE_LOCK_SLEEP = 0.2.seconds

  belongs_to :project
  belongs_to :user
  has_many :relation_exports, class_name: 'Projects::ImportExport::RelationExport'

  validates :project, :jid, :status, presence: true

  STATUS = {
    queued: 0,
    started: 1,
    finished: 2,
    failed: 3
  }.freeze

  scope :updated_at_before, ->(timestamp) { where("updated_at < ?", timestamp) }
  scope :order_by_updated_at, -> { order(:updated_at, :id) }
  scope :by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :queued_or_started, -> { where(status: [STATUS[:queued], STATUS[:started]]) }

  # A job stuck in `started` past StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION is about to be
  # failed by that cron worker, so it is excluded to not occupy a concurrency slot.
  scope :started_and_not_timed_out, -> {
    with_status(:started).where(updated_at: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION.seconds.ago...)
  }
  scope :queued_and_not_timed_out, ->(timeout) { with_status(:queued).where(updated_at: timeout.ago...) }

  state_machine :status, initial: :queued do
    event :start do
      transition [:queued] => :started
    end

    event :finish do
      transition [:started] => :finished
    end

    event :fail_op do
      transition [:queued, :started] => :failed
    end

    state :queued, value: STATUS[:queued]
    state :started, value: STATUS[:started]
    state :finished, value: STATUS[:finished]
    state :failed, value: STATUS[:failed]

    after_transition any => :finished do |export_job|
      export_job.run_after_commit_or_now do
        audit_project_exported
      end
    end
  end

  # Two exports requested close together can both reach this method before either row exists. The lease
  # serializes the find-and-create for a given (project, user) so only one row is ever created
  def self.find_or_create_for(project, user_id, jid:, exported_by_admin:)
    find_queued_or_started(project, user_id) ||
      in_lock("project_export_job:find_or_create_for:#{project.id}:#{user_id}",
        ttl: FIND_OR_CREATE_LOCK_TTL, retries: FIND_OR_CREATE_LOCK_RETRIES, sleep_sec: FIND_OR_CREATE_LOCK_SLEEP) do
        find_queued_or_started(project, user_id) ||
          create!(project: project, user_id: user_id, jid: jid, exported_by_admin: exported_by_admin)
      end
  end

  def self.find_queued_or_started(project, user_id)
    by_user_id(user_id).queued_or_started.find_by(project: project)
  end

  # Only a job that is not re-enqueued keeps its jid, so this lookup is limited to the disabled
  # state of the limit_concurrent_project_exports feature flag, and goes away with it.
  def self.find_or_create_by_jid(project, jid:, user_id:, exported_by_admin:)
    project.export_jobs.find_or_create_by!(jid: jid) do |export_job|
      export_job.user_id = user_id
      export_job.exported_by_admin = exported_by_admin
    end
  end

  # Returns true if this job may start now. Enforces the global concurrency limit while keeping
  # FIFO fairness: the oldest queued jobs claim freed slots first, skipping ones that timed out.
  def next_in_queue?(limit:, timeout:)
    available_capacity = limit - self.class.started_and_not_timed_out.limit(limit).count
    return false if available_capacity <= 0

    self.class.queued_and_not_timed_out(timeout).order(:id).limit(available_capacity).pluck(:id).include?(id)
  end

  def find_or_create_relation_exports!
    Projects::ImportExport::RelationExport.relation_names_list.map do |relation_name|
      relation_exports.find_or_create_by!(relation: relation_name)
    end
  end

  private

  def audit_project_exported
    return if exported_by_admin? && Gitlab::CurrentSettings.silent_admin_exports_enabled?

    audit_context = {
      name: 'project_export_created',
      author: user,
      scope: project,
      target: project,
      message: 'Profile file export was created'
    }

    ::Gitlab::Audit::Auditor.audit(audit_context)
  end
end
