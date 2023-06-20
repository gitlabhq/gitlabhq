# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      class Logger < ::Gitlab::JsonLogger
        exclude_context!

        def self.file_name_noext
          'database_health_status'
        end
      end
    end
  end
end
