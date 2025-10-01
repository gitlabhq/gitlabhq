# frozen_string_literal: true

module Gitlab
  module CoveredExperience
    # This is a temporary method to track the start of a covered experience behind a
    # feature flag. Eventually this will be dropped and we'll call `start` directly
    # in the actions and endpoints.
    #
    # There's no need to add the feature flag in the Sidekiq worker, as Covered Experiences
    # not initiated by the requests aren't going to propagate to the jobs and will be no-ops.
    # Related worker: app/workers/new_merge_request_worker.rb
    def self.start_covered_experience_create_merge_request(project, **args)
      return unless Feature.enabled?(:covered_experience_create_merge_request, project)

      Labkit::CoveredExperience.start(:create_merge_request, **args)
    end
  end
end
