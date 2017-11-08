class Geo::FileRegistry < Geo::BaseRegistry
  scope :failed, -> { where(success: false) }
  scope :synced, -> { where(success: true) }
  scope :to_be_retried, -> { where('retry_at < ?', Time.now) }
end
