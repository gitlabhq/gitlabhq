# frozen_string_literal: true

module Gitlab
  module Tracking
    class SnowplowEventLogger < Gitlab::JsonLogger
      def self.file_name_noext
        'product_usage_data'
      end

      def self.log_level
        ::Logger::INFO
      end
    end
  end
end
