module Geo
  class RepositoryDeletedEvent < ActiveRecord::Base
    include Geo::Model
    include Geo::Eventable

    belongs_to :project

    validates :project, presence: true
  end
end
