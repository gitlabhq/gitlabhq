# frozen_string_literal: true

require 'json'

module Gitlab
  module OmniauthLogging
    class JSONFormatter
      def call(severity, datetime, progname, msg)
        { severity: severity, timestamp: datetime.utc.iso8601(3), pid: $$, progname: progname, message: msg }.to_json << "\n"
      end
    end
  end
end
