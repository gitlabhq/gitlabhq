# frozen_string_literal: true

module IncidentManagement
  class TimelineEventTagLink < ApplicationRecord
    self.table_name = 'incident_management_timeline_event_tag_links'

    belongs_to :timeline_event_tag, class_name: 'IncidentManagement::TimelineEventTag'

    belongs_to :timeline_event, class_name: 'IncidentManagement::TimelineEvent'
  end
end
