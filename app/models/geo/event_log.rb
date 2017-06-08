module Geo
  class EventLog < ActiveRecord::Base
    include Geo::Model

    belongs_to :repository_updated_event,
      class_name: 'Geo::RepositoryUpdatedEvent',
      foreign_key: :repository_updated_event_id
  end
end
