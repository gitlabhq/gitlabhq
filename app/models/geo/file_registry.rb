class Geo::FileRegistry < Geo::BaseRegistry
  scope :failed, -> { where(success: false) }
  scope :synced, -> { where(success: true) }
end
