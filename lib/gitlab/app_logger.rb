# frozen_string_literal: true

module Gitlab
  class AppLogger < Gitlab::MultiDestinationLogger
    LOGGERS = [Gitlab::AppTextLogger, Gitlab::AppJsonLogger].freeze

    def self.loggers
      LOGGERS
    end

    def self.primary_logger
      Gitlab::AppTextLogger
    end
  end
end
