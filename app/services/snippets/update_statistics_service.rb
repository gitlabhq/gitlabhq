# frozen_string_literal: true

module Snippets
  class UpdateStatisticsService
    REPOSITORY_NOT_FOUND = :repository_not_found

    attr_reader :snippet

    def initialize(snippet)
      @snippet = snippet
    end

    def execute
      unless snippet.repository_exists?
        return ServiceResponse.error(
          message: 'Invalid snippet repository',
          reason: REPOSITORY_NOT_FOUND
        )
      end

      snippet.repository.expire_statistics_caches
      statistics.refresh!

      ServiceResponse.success(message: 'Snippet statistics successfully updated.')
    end

    private

    def statistics
      @statistics ||= snippet.statistics || snippet.build_statistics
    end
  end
end
