class Geo::ProjectRegistry < Geo::BaseRegistry
  validates :project_id, presence: true
end
