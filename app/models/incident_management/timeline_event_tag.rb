# frozen_string_literal: true

module IncidentManagement
  class TimelineEventTag < ApplicationRecord
    self.table_name = 'incident_management_timeline_event_tags'

    START_TIME_TAG_NAME = 'Start time'
    END_TIME_TAG_NAME = 'End time'

    belongs_to :project, inverse_of: :incident_management_timeline_event_tags

    has_many :timeline_event_tag_links,
      class_name: 'IncidentManagement::TimelineEventTagLink'

    has_many :timeline_events,
      class_name: 'IncidentManagement::TimelineEvent',
      through: :timeline_event_tag_links

    validates :name, presence: true, format: { with: /\A[^,]+\z/ }
    validates :name, uniqueness: { scope: :project_id, case_sensitive: false }
    validates :name, length: { maximum: 255 }

    scope :by_names, -> (tag_names) { where('lower(name) in (?)', tag_names.map(&:downcase)) }

    def self.pluck_names
      pluck(:name)
    end
  end
end
