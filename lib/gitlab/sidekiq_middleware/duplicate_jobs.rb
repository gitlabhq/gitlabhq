# frozen_string_literal: true

require 'digest'

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      DROPPABLE_QUEUES = Set.new([
        Namespaces::RootStatisticsWorker.queue
      ]).freeze

      def self.drop_duplicates?(queue_name)
        Feature.enabled?(:drop_duplicate_sidekiq_jobs) ||
          drop_duplicates_for_queue?(queue_name)
      end

      private_class_method def self.drop_duplicates_for_queue?(queue_name)
        DROPPABLE_QUEUES.include?(queue_name) &&
          Feature.enabled?(:drop_duplicate_sidekiq_jobs_for_queue)
      end
    end
  end
end
