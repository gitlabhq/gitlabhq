# Concern that sets the queue of a Sidekiq worker based on the worker's class
# name/namespace.
module DedicatedSidekiqQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: name.sub(/Worker\z/, '').underscore.tr('/', '_')
  end
end
