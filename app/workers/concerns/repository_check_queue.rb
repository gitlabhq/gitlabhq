# Concern for setting Sidekiq settings for the various repository check workers.
module RepositoryCheckQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: :repository_check, retry: false
  end
end
