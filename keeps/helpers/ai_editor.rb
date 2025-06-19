# frozen_string_literal: true

module Keeps
  module Helpers
    class AiEditor
      START_OLD_CODE = '<old_code>'
      END_OLD_CODE = '</old_code>'
      START_NEW_CODE = '<new_code>'
      END_NEW_CODE = '</new_code>'
      PATCH_SYSTEM_MESSAGE = File.read(File.expand_path('patch_system_message.md', __dir__))
      AI_MODEL = 'claude-3-7-sonnet-20250219'
      ANTHROPIC_API = 'https://api.anthropic.com/v1/messages'

      attr_reader :model, :token

      def initialize(model: AI_MODEL, token: nil)
        @model = model
        @token = token || ENV['ANTHROPIC_API_KEY']

        raise ArgumentError, 'Anthropic API token is required' if @token.blank?
      end

      def ask_for_and_apply_patch(user_message, file)
        puts "Asking for patch for file #{file}"

        unless File.exist?(file)
          puts "Error: File #{file} doesn't exist"
          return false
        end

        begin
          file_content = File.read(file)
        rescue StandardError => e
          puts "Error reading file #{file}: #{e.message}"
          return false
        end

        user_message += <<~MARKDOWN
        <source_code>
        #{file_content}
        </source_code>
        MARKDOWN

        begin
          response = request(PATCH_SYSTEM_MESSAGE, user_message)

          unless response.code.between?(200, 299)
            puts "API request failed with status #{response.code}: #{response.body}"
            return false
          end

          data = Gitlab::Json.parse(response.body)
          text = data.dig('content', 0, 'text')

          if text.nil?
            puts "Error: AI response is missing expected text content"
            puts "Response data: #{data.inspect}"
            return false
          end

          apply_patch(file, text)
        rescue ::Gitlab::Housekeeper::Shell::Error => e
          puts "Error in ask_for_and_apply_patch: #{e.message}"
          puts e.backtrace.join("\n") if e.backtrace
          false
        end
      end

      private

      def apply_patch(file, ai_response)
        if ai_response.blank?
          puts "Error: AI response is empty for file #{file}. Cannot proceed with patch application."
          return false
        end

        fixed_code = File.read(file)

        changes = extract_changes_from_blocks(ai_response)

        if changes.empty?
          puts "No valid code blocks found in AI response for #{file}"
          return false
        end

        changes.each do |change|
          old_code, new_code = change
          return false if old_code.nil? || new_code.nil?

          fixed_code.gsub!(old_code.lstrip, new_code.lstrip)
        end

        File.write(file, fixed_code)
        true
      end

      def extract_changes_from_blocks(llm_patch)
        old_code_regex = /(?<=#{Regexp.escape(START_OLD_CODE)}).*?(?=#{Regexp.escape(END_OLD_CODE)})/mo
        old_code_match_data = llm_patch.scan(old_code_regex)
        new_code_regex = /(?<=#{Regexp.escape(START_NEW_CODE)}).*?(?=#{Regexp.escape(END_NEW_CODE)})/mo
        new_code_match_data = llm_patch.scan(new_code_regex)

        old_code_match_data.zip(new_code_match_data)
      end

      def request(system, message)
        ::HTTParty.post(
          ANTHROPIC_API,
          headers: {
            'x-api-key' => token
          },
          body: {
            system: system,
            model: model,
            max_tokens: 4096,
            messages: [
              { role: 'user', content: message }
            ]
          }.to_json,
          read_timeout: 60
        )
      end
    end
  end
end
