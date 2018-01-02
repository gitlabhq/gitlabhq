class Geo::EventLogState < Geo::BaseRegistry
  self.primary_key = :event_id

  validates :event_id, presence: true

  def self.last_processed
    order(event_id: :desc).first
  end
end
