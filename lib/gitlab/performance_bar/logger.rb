# frozen_string_literal: true

module Gitlab
  module PerformanceBar
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'performance_bar_json'
      end
    end
  end
end
