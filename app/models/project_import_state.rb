# frozen_string_literal: true

class ProjectImportState < ApplicationRecord
  include AfterCommitQueue
  include ImportState::SidekiqJobTracker

  self.table_name = "project_mirror_data"

  attr_accessor :user_mapping_enabled, :safe_import_url

  after_commit :expire_etag_cache

  belongs_to :project, inverse_of: :import_state

  validates :project, presence: true
  validates :checksums, json_schema: { filename: "project_import_stats" }

  alias_attribute :correlation_id, :correlation_id_value

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

    event :cancel do
      transition [:none, :scheduled, :started] => :canceled
    end

    event :fail_op do
      transition [:scheduled, :started] => :failed
    end

    state :scheduled
    state :started
    state :finished
    state :failed
    state :canceled

    after_transition [:none, :finished, :failed] => :scheduled do |state, _|
      state.run_after_commit do
        job_id = project.add_import_job

        if job_id
          correlation_id = Labkit::Correlation::CorrelationId.current_or_new_id
          update(jid: job_id, correlation_id_value: correlation_id)
        end
      end
    end

    after_transition any => [:canceled, :finished] do |state, _|
      if state.jid.present?
        Gitlab::SidekiqStatus.unset(state.jid)

        state.update_column(:jid, nil)
      end
    end

    after_transition any => [:canceled, :failed] do |state, _|
      state.set_notification_data
      state.project.remove_import_data
    end

    before_transition started: [:finished, :canceled, :failed] do |state, _|
      project = state.project

      if project.github_import?
        import_stats = ::Gitlab::GithubImport::ObjectCounter.summary(state.project)

        state.update_column(:checksums, import_stats)
      end
    end

    after_transition started: :finished do |state, _|
      project = state.project

      state.set_notification_data
      project.reset_cache_and_import_attrs

      if Gitlab::ImportSources.values.include?(project.import_type) && project.repo_exists? # rubocop: disable Performance/InefficientHashSearch -- not a Hash
        state.run_after_commit do
          Projects::AfterImportWorker.perform_async(project.id)
        end
      end

      state.send_completion_notification
    end

    after_transition any => [:failed] do |state, _|
      state.set_notification_data
      state.send_completion_notification(notify_group_owners: false)
    end
  end

  def expire_etag_cache
    if realtime_changes_path
      Gitlab::EtagCaching::Store.new.tap do |store|
        store.touch(realtime_changes_path)
      rescue Gitlab::EtagCaching::Store::InvalidKeyError
        # no-op: not every realtime changes endpoint is using etag caching
      end
    end
  end

  def realtime_changes_path
    Gitlab::Routing.url_helpers.polymorphic_path([:realtime_changes_import, project.import_type.to_sym], format: :json)
  rescue NoMethodError
    # polymorphic_path throws NoMethodError when no such path exists
    nil
  end

  def relation_hard_failures(limit:)
    project.import_failures.hard_failures_by_correlation_id(correlation_id).limit(limit)
  end

  def mark_as_failed(error_message)
    original_errors = errors.dup
    sanitized_message = Gitlab::UrlSanitizer.sanitize(error_message)

    fail_op

    update_column(:last_error, sanitized_message)
  rescue ActiveRecord::ActiveRecordError => e
    ::Import::Framework::Logger.error(
      message: 'Error setting import status to failed',
      error: e.message,
      original_error: sanitized_message
    )
  ensure
    @errors = original_errors
  end

  alias_method :no_import?, :none?

  # This method is coupled to the repository mirror domain.
  # Use with caution in the importers domain. As an alternative, use the `#completed?` method.
  # See EE-override and https://gitlab.com/gitlab-org/gitlab/-/merge_requests/4697
  def in_progress?
    scheduled? || started?
  end

  def completed?
    finished? || failed? || canceled?
  end

  def started?
    # import? does SQL work so only run it if it looks like there's an import running
    status == 'started' && project.import?
  end

  def send_completion_notification(notify_group_owners: true)
    return unless project.notify_project_import_complete?

    run_after_commit do
      Projects::ImportExport::ImportCompletionNotificationWorker.perform_async(
        project.id,
        'user_mapping_enabled' => user_mapping_enabled?,
        'notify_group_owners' => notify_group_owners,
        'safe_import_url' => safe_import_url
      )
    end
  end

  def set_notification_data
    self.user_mapping_enabled ||= project.import_data&.user_mapping_enabled?
    self.safe_import_url ||= project.safe_import_url(masked: false)
  end

  private

  # Return whether or not user mapping was enabled during the project's import to determine who to
  # send completion emails to. user_mapping_enabled should be set if import_data is removed.
  # This can be removed when all 3rd party project importer user mapping feature flags are removed.
  def user_mapping_enabled?
    user_mapping_enabled || project.import_data&.user_mapping_enabled?
  end
end

ProjectImportState.prepend_mod_with('ProjectImportState')
