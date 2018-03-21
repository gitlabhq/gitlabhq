##
# Concern for setting Sidekiq settings for the low priority CI pipeline workers.
#
module PipelineBackgroundQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :pipeline_background
  end
end
