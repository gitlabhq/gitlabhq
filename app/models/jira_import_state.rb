# frozen_string_literal: true

class JiraImportState < ApplicationRecord
  include AfterCommitQueue
  include ImportState::SidekiqJobTracker
  include UsageStatistics

  self.table_name = 'jira_imports'

  ERROR_MESSAGE_SIZE = 1000 # 1000 characters limit
  STATUSES = { initial: 0, scheduled: 1, started: 2, failed: 3, finished: 4 }.freeze

  belongs_to :project
  belongs_to :user
  belongs_to :label

  scope :by_jira_project_key, ->(jira_project_key) { where(jira_project_key: jira_project_key) }
  scope :with_status, ->(statuses) { where(status: statuses) }

  validates :project, presence: true
  validates :jira_project_key, presence: true
  validates :jira_project_name, presence: true
  validates :jira_project_xid, presence: true

  validates :project, uniqueness: {
    conditions: -> { where.not(status: STATUSES.values_at(:failed, :finished)) },
    message: N_('Cannot have multiple Jira imports running at the same time')
  }

  before_save :ensure_error_message_size

  alias_method :scheduled_by, :user

  state_machine :status, initial: :initial do
    event :schedule do
      transition initial: :scheduled
    end

    event :start do
      transition scheduled: :started
    end

    event :finish do
      transition started: :finished
    end

    event :do_fail do
      transition [:initial, :scheduled, :started] => :failed
    end

    after_transition initial: :scheduled do |state, _|
      state.run_after_commit do
        job_id = Gitlab::JiraImport::Stage::StartImportWorker.perform_async(project.id)
        state.update(jid: job_id, scheduled_at: Time.current) if job_id
      end
    end

    before_transition any => :finished do |state, _|
      InternalId.flush_records!(project: state.project)
      state.project.update_project_counter_caches
      state.store_issue_counts
    end

    after_transition any => :finished do |state, _|
      if state.jid.present?
        Gitlab::SidekiqStatus.unset(state.jid)

        state.update_column(:jid, nil)
      end
    end

    after_transition any => :failed do |state, transition|
      arguments_hash = transition.args.first
      error_message = arguments_hash&.dig(:error_message)

      state.update_column(:error_message, error_message) if error_message.present?
    end

    # Supress warning:
    # both JiraImportState and its :status machine have defined a different default for "status".
    # although both have same value but represented in 2 ways: integer(0) and symbol(:initial)
    def owner_class_attribute_default
      'initial'
    end
  end

  enum status: STATUSES

  def in_progress?
    scheduled? || started?
  end

  def non_initial?
    !initial?
  end

  def store_issue_counts
    import_label_id = Gitlab::JiraImport.get_import_label_id(project.id)

    failed_to_import_count = Gitlab::JiraImport.issue_failures(project.id)
    successfully_imported_count = project.issues.with_label_ids(import_label_id).count
    total_issue_count = successfully_imported_count + failed_to_import_count

    update(
      {
        failed_to_import_count: failed_to_import_count,
        imported_issues_count: successfully_imported_count,
        total_issue_count: total_issue_count
      }
    )
  end

  def mark_as_failed(error_message)
    sanitized_message = Gitlab::UrlSanitizer.sanitize(error_message)

    do_fail(error_message: error_message)
  rescue ActiveRecord::ActiveRecordError => e
    Gitlab::AppLogger.error("Error setting import status to failed: #{e.message}. Original error: #{sanitized_message}")
  end

  private

  def ensure_error_message_size
    self.error_message = error_message&.truncate(ERROR_MESSAGE_SIZE)
  end
end
