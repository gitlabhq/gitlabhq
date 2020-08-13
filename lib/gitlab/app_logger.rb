# frozen_string_literal: true

module Gitlab
  class AppLogger < Gitlab::MultiDestinationLogger
    LOGGERS = [Gitlab::AppTextLogger, Gitlab::AppJsonLogger].freeze

    def self.loggers
      if Gitlab::Utils.to_boolean(ENV.fetch('UNSTRUCTURED_RAILS_LOG', 'true'))
        LOGGERS
      else
        [Gitlab::AppJsonLogger]
      end
    end

    def self.primary_logger
      Gitlab::AppTextLogger
    end
  end
end
