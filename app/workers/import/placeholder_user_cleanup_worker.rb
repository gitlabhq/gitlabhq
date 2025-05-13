# frozen_string_literal: true

module Import
  class PlaceholderUserCleanupWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- no relevant metadata

    idempotent!
    data_consistency :sticky
    feature_category :importers
    deduplicate :until_executed
    MAX_ATTEMPTS = 15

    def perform
      Import::PlaceholderUserDetail.eligible_for_deletion.find_each.with_index do |detail, index|
        detail.increment_deletion_attempt
        log_max_attempts_warning(detail) if max_attempts_reached?(detail)

        delay = index * 1.second

        Import::DeletePlaceholderUserWorker
        .perform_in(delay, detail.placeholder_user_id, { type: 'placeholder_user' })
      end
    end

    def max_attempts_reached?(detail)
      detail.deletion_attempts + 1 >= MAX_ATTEMPTS
    end

    def log_max_attempts_warning(detail)
      ::Import::Framework::Logger.warn(
        message: "Maximum deletion attempts (#{MAX_ATTEMPTS}) reached for deletion of placeholder user." \
          "Making final deletion attempt.",
        placeholder_user_id: detail.placeholder_user_id
      )
    end
  end
end
