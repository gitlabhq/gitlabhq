# frozen_string_literal: true

module Gitlab
  class AuditJsonLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'audit_json'
    end
  end
end
