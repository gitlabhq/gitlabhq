##
# Concern for setting Sidekiq settings for the various CI pipeline workers.
#
module PipelineQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: 'pipeline_default'
  end

  class_methods do
    def enqueue_in(group:)
      raise ArgumentError, 'Unspecified queue group!' if group.empty?

      sidekiq_options queue: "pipeline_#{group}"
    end
  end
end
