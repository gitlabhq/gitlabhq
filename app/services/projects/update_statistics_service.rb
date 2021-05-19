# frozen_string_literal: true

module Projects
  class UpdateStatisticsService < BaseService
    include ::Gitlab::Utils::StrongMemoize

    STAT_TO_CACHED_METHOD = {
      repository_size: :size,
      commit_count: :commit_count
    }.freeze

    def execute
      return unless project

      Gitlab::AppLogger.info("Updating statistics for project #{project.id}")

      expire_repository_caches
      expire_wiki_caches
      project.statistics.refresh!(only: statistics)
    end

    private

    def expire_repository_caches
      if statistics.empty?
        project.repository.expire_statistics_caches
      elsif method_caches_to_expire.present?
        project.repository.expire_method_caches(method_caches_to_expire)
      end
    end

    def expire_wiki_caches
      return unless project.wiki_enabled? && statistics.include?(:wiki_size)

      project.wiki.repository.expire_method_caches([:size])
    end

    def method_caches_to_expire
      strong_memoize(:method_caches_to_expire) do
        statistics.map { |stat| STAT_TO_CACHED_METHOD[stat] }.compact
      end
    end

    def statistics
      strong_memoize(:statistics) do
        params[:statistics]&.map(&:to_sym)
      end
    end
  end
end
