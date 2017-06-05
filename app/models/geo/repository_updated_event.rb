module Geo
  class RepositoryUpdatedEvent < ActiveRecord::Base
    include Geo::Model

    REPOSITORY = 0
    WIKI       = 1

    belongs_to :project

    enum source: { repository: REPOSITORY, wiki: WIKI }

    validates :project, presence: true
  end
end
