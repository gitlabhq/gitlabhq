# frozen_string_literal: true

class ProjectImportState < ApplicationRecord
  include AfterCommitQueue

  self.table_name = "project_mirror_data"

  belongs_to :project, inverse_of: :import_state

  validates :project, presence: true

  state_machine :status, initial: :none do
    event :schedule do
      transition [:none, :finished, :failed] => :scheduled
    end

    event :force_start do
      transition [:none, :finished, :failed] => :started
    end

    event :start do
      transition scheduled: :started
    end

    event :finish do
      transition started: :finished
    end

    event :fail_op do
      transition [:scheduled, :started] => :failed
    end

    state :scheduled
    state :started
    state :finished
    state :failed

    after_transition [:none, :finished, :failed] => :scheduled do |state, _|
      state.run_after_commit do
        job_id = project.add_import_job
        update(jid: job_id) if job_id
      end
    end

    after_transition any => :finished do |state, _|
      if state.jid.present?
        Gitlab::SidekiqStatus.unset(state.jid)

        state.update_column(:jid, nil)
      end
    end

    after_transition started: :finished do |state, _|
      project = state.project

      project.reset_cache_and_import_attrs

      if Gitlab::ImportSources.importer_names.include?(project.import_type) && project.repo_exists?
        # rubocop: disable CodeReuse/ServiceClass
        state.run_after_commit do
          Projects::AfterImportService.new(project).execute
        end
        # rubocop: enable CodeReuse/ServiceClass
      end
    end
  end

  def mark_as_failed(error_message)
    original_errors = errors.dup
    sanitized_message = Gitlab::UrlSanitizer.sanitize(error_message)

    fail_op

    update_column(:last_error, sanitized_message)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("Error setting import status to failed: #{e.message}. Original error: #{sanitized_message}") # rubocop:disable Gitlab/RailsLogger
  ensure
    @errors = original_errors
  end

  alias_method :no_import?, :none?

  def in_progress?
    scheduled? || started?
  end

  def started?
    # import? does SQL work so only run it if it looks like there's an import running
    status == 'started' && project.import?
  end

  # Refreshes the expiration time of the associated import job ID.
  #
  # This method can be used by asynchronous importers to refresh the status,
  # preventing the StuckImportJobsWorker from marking the import as failed.
  def refresh_jid_expiration
    return unless jid

    Gitlab::SidekiqStatus.set(jid, StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION)
  end
end

ProjectImportState.prepend_if_ee('EE::ProjectImportState')
