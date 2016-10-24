# Concern for setting Sidekiq settings for the various GitLab GEO workers.
module GeoQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: :geo
  end
end
