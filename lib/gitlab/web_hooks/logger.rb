# frozen_string_literal: true

module Gitlab
  module WebHooks
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'web_hooks'
      end
    end
  end
end
