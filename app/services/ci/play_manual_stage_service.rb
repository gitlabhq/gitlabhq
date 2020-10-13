# frozen_string_literal: true

module Ci
  class PlayManualStageService < BaseService
    def initialize(project, current_user, params)
      super

      @pipeline = params[:pipeline]
    end

    def execute(stage)
      stage.processables.manual.each do |processable|
        next unless processable.playable?

        processable.play(current_user)
      rescue Gitlab::Access::AccessDeniedError
        logger.error(message: 'Unable to play manual action', processable_id: processable.id)
      end
    end

    private

    attr_reader :pipeline, :current_user

    def logger
      Gitlab::AppLogger
    end
  end
end
