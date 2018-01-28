##
# Concern for setting Sidekiq settings for the various CI pipeline workers.
#
module PipelineQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :pipeline_default
  end
end
