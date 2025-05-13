# frozen_string_literal: true

# Usage examples:
#
# For a specific file:
#    ```
#    bundle exec rake "product_usage_data:format[log/product_usage_data.log]"
#    ```
#
# For standard input (pipe data to it):
#    ```
#    cat log/product_usage_data.log | bundle exec rake product_usage_data:format
#    ```
#
# For continuous monitoring:
#    ```
#    tail -f log/product_usage_data.log | bundle exec rake product_usage_data:format
#    ```
#
# Motivation:
#   This task formats GitLab product usage data event logs for better readability.
#   It pretty-prints the JSON and decodes the base64 encoded "cx" field in the payload.
#   The task reads from files provided as arguments or from standard input.
#
namespace :product_usage_data do
  desc 'Format GitLab product usage data event logs for better readability'
  task :format, :file_path do |_t, args|
    # Handle file path argument or use standard input
    if args[:file_path]
      input = File.open(args[:file_path], 'r')
    else
      puts "No file specified, reading from standard input. Press Ctrl+D when finished."
      input = $stdin
    end

    # rubocop:disable Gitlab/Json -- Speed of loading the full environment isn't worthwhile
    input.each_line do |line|
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
    # rubocop:enable Gitlab/Json

    # Close the file if we opened one
    input.close if args[:file_path]
  end
end
