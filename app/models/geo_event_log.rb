class GeoEventLog < ActiveRecord::Base
  belongs_to :push_event, class_name: 'GeoPushEvent', foreign_key: 'push_event_id'
end
