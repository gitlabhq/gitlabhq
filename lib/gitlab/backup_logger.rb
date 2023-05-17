# frozen_string_literal: true

module Gitlab
  class BackupLogger < Gitlab::JsonLogger
    exclude_context!

    def self.file_name_noext
      'backup_json'
    end
  end
end
