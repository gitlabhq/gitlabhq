# Concern for setting Sidekiq settings for the various GitLab GEO workers.
module GeoQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :geo
  end
end
