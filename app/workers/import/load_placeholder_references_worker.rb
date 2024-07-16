# frozen_string_literal: true

module Import
  class LoadPlaceholderReferencesWorker
    include ApplicationWorker

    data_consistency :delayed
    deduplicate :until_executed, if_deduplicated: :reschedule_once
    idempotent!
    feature_category :importers
    loggable_arguments 0, 1

    def perform(import_source, import_uid, params = {})
      return unless Feature.enabled?(:importer_user_mapping, User.actor_from_id(params['current_user_id']))

      ::Import::PlaceholderReferences::LoadService.new(
        import_source: import_source,
        import_uid: import_uid
      ).execute
    end
  end
end
