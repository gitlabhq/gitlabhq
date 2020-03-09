# frozen_string_literal: true

require 'digest'

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      def self.drop_duplicates?
        Feature.enabled?(:drop_duplicate_sidekiq_jobs)
      end
    end
  end
end
