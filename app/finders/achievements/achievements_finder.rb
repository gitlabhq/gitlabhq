# frozen_string_literal: true

module Achievements
  class AchievementsFinder
    attr_reader :namespace, :params

    def initialize(namespace, params = {})
      @namespace = namespace
      @params = params
    end

    def execute
      achievements = namespace.achievements
      by_ids(achievements)
    end

    private

    def by_ids(achievements)
      return achievements unless ids?

      achievements.id_in(params[:ids])
    end

    def ids?
      params[:ids].present?
    end
  end
end
