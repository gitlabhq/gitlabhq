# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class Logger < ::Gitlab::JsonLogger
        def self.file_name_noext
          'database_load_balancing'
        end
      end
    end
  end
end
