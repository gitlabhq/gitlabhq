# frozen_string_literal: true

module Gitlab
  module Export
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'exporter'
      end
    end
  end
end
