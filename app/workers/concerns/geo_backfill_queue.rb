# Concern for setting Sidekiq settings for Geo backfill worker.
module GeoBackfillQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: :geo_backfill, retry: false
  end
end
