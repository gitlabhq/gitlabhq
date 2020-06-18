# frozen_string_literal: true

module Projects
  class UpdateStatisticsService < BaseService
    def execute
      return unless project

      Gitlab::AppLogger.info("Updating statistics for project #{project.id}")

      project.statistics.refresh!(only: statistics.map(&:to_sym))
    end

    private

    def statistics
      params[:statistics]
    end
  end
end
