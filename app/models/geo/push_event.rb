module Geo
  class PushEvent < ActiveRecord::Base
    include Geo::Model

    REPOSITORY = 0
    WIKI       = 1

    belongs_to :project

    enum source: { repository: 0, wiki: 1 }

    validates :project, presence: true
  end
end
