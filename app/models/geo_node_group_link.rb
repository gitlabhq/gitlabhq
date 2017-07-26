class GeoNodeGroupLink < ActiveRecord::Base
  belongs_to :geo_node
  belongs_to :group

  validates :geo_node_id, :group_id, presence: true
  validates :group_id, uniqueness: { scope: [:geo_node_id] }
end
