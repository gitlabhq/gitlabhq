# frozen_string_literal: true

module Timelogs
  class BaseService
    include BaseServiceUtility
    include Gitlab::Utils::StrongMemoize

    attr_accessor :current_user

    def initialize(user)
      @current_user = user
    end

    def success(timelog)
      ServiceResponse.success(payload: {
        timelog: timelog
      })
    end

    def error(message, http_status = nil)
      ServiceResponse.error(message: message, http_status: http_status)
    end

    def error_in_save(timelog)
      return error(_("Failed to save timelog"), 404) if timelog.errors.empty?

      error(timelog.errors.full_messages.to_sentence, 404)
    end
  end
end
