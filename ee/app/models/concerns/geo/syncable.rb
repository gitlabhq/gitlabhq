module Geo::Syncable
  extend ActiveSupport::Concern

  included do
    scope :failed, -> { where(success: false) }
    scope :synced, -> { where(success: true) }
    scope :retry_due, -> { where('retry_at is NULL OR retry_at < ?', Time.now) }
    scope :missing_on_primary, -> { where(missing_on_primary: true) }
  end
end
