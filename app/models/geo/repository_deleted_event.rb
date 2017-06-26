module Geo
  class RepositoryDeletedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :project

    validates :project, presence: true
  end
end
