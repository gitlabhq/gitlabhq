# frozen_string_literal: true

module Gitlab
  module Services
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'service_measurement'
      end
    end
  end
end
