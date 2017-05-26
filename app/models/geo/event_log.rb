module Geo
  class EventLog < ActiveRecord::Base
    include Geo::Model

    belongs_to :push_event, class_name: 'Geo::PushEvent', foreign_key: 'push_event_id'
  end
end
