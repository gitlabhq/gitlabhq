# frozen_string_literal: true

module AuditEvents
  module HttpTimeoutConfig
    DEFAULT = {
      open_timeout: 8.seconds,
      read_timeout: 8.seconds,
      write_timeout: 8.seconds
    }.freeze
  end
end
