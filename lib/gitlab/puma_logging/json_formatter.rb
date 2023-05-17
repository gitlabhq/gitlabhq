# frozen_string_literal: true

require 'json'
require 'time'

module Gitlab
  module PumaLogging
    class JSONFormatter
      def call(str)
        { timestamp: Time.now.utc.iso8601(3), pid: $$, message: str }.to_json
      end
    end
  end
end
