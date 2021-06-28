# frozen_string_literal: true

module Gitlab
  class BackupLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'backup_json'
    end
  end
end
