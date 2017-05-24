class GeoPushEvent < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true

  enum event_type: { repository_updated: 0, wiki_updated: 1 }
end
