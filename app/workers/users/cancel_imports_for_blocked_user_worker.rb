# frozen_string_literal: true

module Users
  class CancelImportsForBlockedUserWorker
    include ApplicationWorker

    data_consistency :delayed
    defer_on_database_health_signal :gitlab_main_org, [:project_mirror_data, :bulk_imports], 1.minute

    deduplicate :until_executed
    idempotent!
    feature_category :importers
    urgency :low

    def perform(user_id)
      user = User.find_by_id(user_id)
      # Only the block and ban transitions enqueue this, so ldap_blocked and blocked_pending_approval never reach it.
      return unless user&.blocked?

      log_extra_metadata_on_done(:canceled_project_imports, cancel_project_imports(user))
      log_extra_metadata_on_done(:canceled_bulk_imports, cancel_bulk_imports(user))
    end

    private

    def cancel_project_imports(user)
      canceled = 0

      user.created_projects.each_batch do |projects|
        projects.is_importing.each do |project|
          # Pull mirror syncs are not one-off imports; mirror scheduling handles them.
          next if project.read_attribute(:mirror)

          canceled += 1 if safely_cancel(project.import_state, Labkit::Fields::GL_PROJECT_ID => project.id,
            import_type: project.import_type)
        end
      end

      canceled
    end

    def cancel_bulk_imports(user)
      canceled = 0

      user.bulk_imports.with_status(:created, :started).each_batch do |bulk_imports|
        bulk_imports.each do |bulk_import|
          canceled += 1 if safely_cancel(bulk_import, bulk_import_id: bulk_import.id)
        end
      end

      canceled
    end

    # One record failing (e.g. a race with the import finishing) must not stop the others.
    def safely_cancel(record, log_fields)
      record.cancel
    rescue StandardError => e
      ::Import::Framework::Logger.error(
        message: 'Failed to cancel import for blocked user',
        Labkit::Fields::ERROR_MESSAGE => e.message,
        **log_fields
      )

      false
    end
  end
end
