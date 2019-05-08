# frozen_string_literal: true

module Ci
  class PlayManualStageService < BaseService
    def initialize(project, current_user, params)
      super

      @pipeline = params[:pipeline]
    end

    def execute(stage)
      stage.builds.manual.each do |build|
        next unless build.playable?

        build.play(current_user)
      rescue Gitlab::Access::AccessDeniedError
        logger.error(message: 'Unable to play manual action', build_id: build.id)
      end
    end

    private

    attr_reader :pipeline, :current_user

    def logger
      Gitlab::AppLogger
    end
  end
end
