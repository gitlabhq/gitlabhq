# frozen_string_literal: true

module Gitlab
  module Sentry
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'exceptions_json'
      end
    end
  end
end
