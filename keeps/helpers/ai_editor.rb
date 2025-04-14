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
        user_message += <<~MARKDOWN
        <source_code>
        #{File.read(file)}
        </source_code>
        MARKDOWN

        puts user_message

        response = request(PATCH_SYSTEM_MESSAGE, user_message)
        data = Gitlab::Json.parse(response.body)
        text = data.dig('content', 0, 'text')

        apply_patch(file, text)
      end

      private

      def apply_patch(file, ai_response)
        return false if ai_response.empty?

        fixed_code = File.read(file)

        changes = extract_changes_from_blocks(ai_response)

        return false if changes.empty?

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
