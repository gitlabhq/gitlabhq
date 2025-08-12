# frozen_string_literal: true

module Mcp
  module Tools
    # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolresult
    module Response
      TEXT_CONTENT = 'text'

      def self.success(formatted_content, data = nil)
        {
          content: formatted_content,
          structuredContent: format_structured_content(data),
          isError: false
        }
      end

      def self.error(message, details = nil)
        {
          content: [{ type: TEXT_CONTENT, text: message.to_s }],
          structuredContent: details ? { error: details } : {},
          isError: true
        }
      end

      def self.format_text(item)
        (item.is_a?(Hash) && item['web_url']) || item.map { |key, value| "#{key.to_s.humanize}: #{value}" }.join("\n")
      end
      private_class_method :format_text

      def self.format_content(data)
        case data
        when Hash
          [{ type: TEXT_CONTENT, text: format_text(data) }]
        when Array
          data.map { |item| { type: TEXT_CONTENT, text: format_text(item) } }
        else
          data.to_json
        end
      end
      private_class_method :format_content

      def self.format_structured_content(data)
        case data
        when Hash
          data
        when Array
          {
            items: data,
            metadata: {
              count: data.length,
              has_more: false
            }
          }
        else
          {}
        end
      end
      private_class_method :format_structured_content
    end
  end
end
