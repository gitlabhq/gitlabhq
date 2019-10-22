# frozen_string_literal: true

##
# Concern for setting Sidekiq settings for the various ObjectPool queues
#
module ObjectPoolQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :object_pool
    feature_category :gitaly
  end
end
