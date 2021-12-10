# frozen_string_literal: true

module Gitlab
  module RepositoryArchiveRateLimiter
    def check_archive_rate_limit!(current_user, project, &block)
      return unless Feature.enabled?(:archive_rate_limit)

      threshold = current_user ? nil : 100

      check_rate_limit!(:project_repositories_archive, scope: [project, current_user], threshold: threshold, &block)
    end
  end
end
