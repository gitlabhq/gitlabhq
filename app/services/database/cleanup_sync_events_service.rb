# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- existing module that holds the related sync services
  # Deletes sync events that every active consumer has synced. Batched by
  # primary key so the deletes never need an index on the sync flag columns
  # and stay cheap while a backlog is draining.
  class CleanupSyncEventsService
    BATCH_SIZE = 1000

    def initialize(sync_event_class)
      @sync_event_class = sync_event_class
    end

    def execute
      { deleted_events: @sync_event_class.delete_synced_events(batch_size: BATCH_SIZE) }
    end
  end
end
