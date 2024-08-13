# frozen_string_literal: true

module AntiAbuse
  class Event < ApplicationRecord
    self.table_name = 'abuse_events'

    validates :category, presence: true
    validates :source, presence: true
    validates :user, presence: true, on: :create
    validates :metadata, json_schema: { filename: 'abuse_event_metadata' }, allow_blank: true

    belongs_to :user, inverse_of: :abuse_events
    belongs_to :abuse_report, inverse_of: :abuse_events

    enum category: Enums::Abuse::Category.categories
    enum source: Enums::Abuse::Source.sources
  end
end
