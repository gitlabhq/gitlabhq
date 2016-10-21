# Concern that sets various Sidekiq settings for workers executed using a
# cronjob.
module CronjobQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: :cronjob, retry: false
  end
end
