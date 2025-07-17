# frozen_string_literal: true

module Gitlab
  module ActiveContext
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'activecontext'
      end
    end
  end
end
