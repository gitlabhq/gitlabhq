# frozen_string_literal: true

module Gitlab
  module Backup
    class JsonLogger < Gitlab::JsonLogger
      exclude_context!

      def self.file_name_noext
        'backup_json'
      end
    end
  end
end
