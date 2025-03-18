# frozen_string_literal: true

module EventForward
  class Logger < ::Gitlab::JsonLogger
    def self.file_name_noext
      'event_collection'
    end
  end
end
