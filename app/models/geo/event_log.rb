module Geo
  class EventLog < ActiveRecord::Base
    include Geo::Model

    delegate :project_id, to: :event, allow_nil: true

    belongs_to :repository_updated_event,
      class_name: 'Geo::RepositoryUpdatedEvent',
      foreign_key: :repository_updated_event_id

    belongs_to :repository_deleted_event,
      class_name: 'Geo::RepositoryDeletedEvent',
      foreign_key: :repository_deleted_event_id

    belongs_to :repository_renamed_event,
      class_name: 'Geo::RepositoryRenamedEvent',
      foreign_key: :repository_renamed_event_id

    belongs_to :repositories_changed_event,
      class_name: 'Geo::RepositoriesChangedEvent',
      foreign_key: :repositories_changed_event_id

    def event
      repository_updated_event ||
        repository_deleted_event ||
        repository_renamed_event ||
        repositories_changed_event
    end
  end
end
