# frozen_string_literal: true

module Gitlab
  class AppLogger < Gitlab::MultiDestinationLogger
    def self.loggers
      [Gitlab::AppJsonLogger]
    end

    def self.primary_logger
      Gitlab::AppJsonLogger
    end
  end
end
