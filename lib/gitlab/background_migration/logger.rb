# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Logger that can be used for migrations logging
    class Logger < ::Gitlab::JsonLogger
      exclude_context!

      def self.file_name_noext
        'migrations'
      end
    end
  end
end
