#!/usr/bin/env ruby

# frozen_string_literal: true

# Usage:
#   scripts/product_usage_data_event_formatter.rb [file...]
#
# Examples:
#   scripts/product_usage_data_event_formatter.rb log/product_usage_data.log
#   cat log/product_usage_data.log | scripts/product_usage_data_event_formatter.rb
#   tail -f log/product_usage_data.log | scripts/product_usage_data_event_formatter.rb
#
# Description:
#   This script formats GitLab product usage data event logs for better readability.
#   It pretty-prints the JSON and decodes the base64 encoded "cx" field in the payload.
#   The script reads from files provided as arguments or from standard input.

require 'json'
require 'base64'

ARGF.each_line do |line|
  # Parse the outer JSON
  data = JSON.parse(line.strip)

  # Parse the payload JSON string
  if data["payload"] && data["payload"].start_with?('{')
    payload = JSON.parse(data["payload"])

    # Decode the cx field if it exists
    if payload["cx"]
      begin
        decoded_cx = JSON.parse(Base64.decode64(payload["cx"]))
        payload["cx"] = decoded_cx
      rescue StandardError
        # Ignore the error and use the original value
      end
    end

    # Replace the original payload with the parsed version
    data["payload"] = payload
  end

  # Pretty print the result
  puts JSON.pretty_generate(data)
rescue StandardError => e
  puts "Error processing line: #{e.message}"
  puts line
end
