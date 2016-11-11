# Concern for setting Sidekiq settings for the various CI pipeline workers.
module PipelineQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: :pipeline
  end
end
