# frozen_string_literal: true

require 'logger'

module Gitlab
  module Memory
    class DiagnosticReportsLogger < ::Logger
      def format_message(severity, timestamp, progname, message)
        data = {}
        data[:severity] = severity
        data[:time] = timestamp.utc.iso8601(3)

        data.merge!(message)

        "#{JSON.generate(data)}\n" # rubocop:disable Gitlab/Json
      end
    end
  end
end
