# frozen_string_literal: true

##
# Concern for setting Sidekiq settings for the low priority CI pipeline workers.
#
module PipelineBackgroundQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :pipeline_background
    feature_category :continuous_integration
  end
end
