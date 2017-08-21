##
# Concern for setting Sidekiq settings for the various CI pipeline workers.
#
module PipelineQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: 'pipelines-default'
  end

  class_methods do
    def enqueue_in(queue:, group:)
      raise ArgumentError if queue.empty? || group.empty?

      sidekiq_options queue: "pipelines-#{queue}-#{group}"
    end
  end
end
