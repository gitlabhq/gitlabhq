# frozen_string_literal: true

module Import
  class ReassignPlaceholderUserRecordsWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    idempotent!
    data_consistency :sticky
    feature_category :importers
    deduplicate :until_executed
    sidekiq_options retry: 5, dead: false
    sidekiq_options max_retries_after_interruption: 20

    sidekiq_retries_exhausted do |msg, exception|
      new.perform_failure(exception, msg['args'])
    end

    def perform(import_source_user_id, _params = {})
      @import_source_user = Import::SourceUser.find_by_id(import_source_user_id)

      return unless Feature.enabled?(
        :importer_user_mapping,
        User.actor_from_id(import_source_user&.reassigned_by_user_id)
      )

      return unless import_source_user_valid?

      Import::ReassignPlaceholderUserRecordsService.new(import_source_user).execute
    end

    def perform_failure(exception, import_source_user_id)
      @import_source_user = Import::SourceUser.find_by_id(import_source_user_id)

      log_and_fail_reassignment(exception)
    end

    private

    attr_reader :import_source_user

    def import_source_user_valid?
      return true if import_source_user && import_source_user.reassignment_in_progress?

      ::Import::Framework::Logger.warn(
        message: 'Unable to begin reassignment because Import source user has an invalid status or does not exist',
        source_user_id: import_source_user&.id
      )

      false
    end

    def log_and_fail_reassignment(exception)
      ::Import::Framework::Logger.error(
        message: 'Failed to reassign placeholder user',
        error: exception.message,
        source_user_id: import_source_user&.id
      )

      import_source_user.fail_reassignment!
    end
  end
end
