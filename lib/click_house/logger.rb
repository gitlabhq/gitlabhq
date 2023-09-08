# frozen_string_literal: true

module ClickHouse
  class Logger < ::Gitlab::JsonLogger
    exclude_context!

    def self.file_name_noext
      'clickhouse'
    end
  end
end
