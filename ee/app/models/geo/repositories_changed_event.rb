module Geo
  class RepositoriesChangedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :geo_node

    validates :geo_node, presence: true
  end
end
