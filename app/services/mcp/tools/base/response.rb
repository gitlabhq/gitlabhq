# frozen_string_literal: true

module Mcp
  module Tools
    module Base
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolresult
      module Response
        TEXT_CONTENT = 'text'
        RATE_LIMITED_ERROR_TYPE = 'rate_limited'

        module Reason
          BAD_REQUEST = :bad_request
          UNAUTHORIZED = :unauthorized
          NOT_FOUND = :not_found
          ERROR = :error

          ALL = [BAD_REQUEST, UNAUTHORIZED, NOT_FOUND, ERROR].freeze
        end

        def self.success(formatted_content, data = nil)
          {
            content: formatted_content,
            structuredContent: format_structured_content(data),
            isError: false
          }
        end

        def self.error(message, details = nil, reason: nil)
          result = {
            content: [{ type: TEXT_CONTENT, text: message.to_s }],
            structuredContent: details.nil? ? {} : { error: details },
            isError: true
          }
          result[:reason] = reason if reason.present?
          result
        end

        def self.error_reason(result)
          reason = result[:reason]
          Reason::ALL.include?(reason) ? reason : Reason::ERROR
        end

        def self.reason_for_http_status(status)
          case status.to_i
          when 401, 403 then Reason::UNAUTHORIZED
          when 404 then Reason::NOT_FOUND
          when 408, 429 then Reason::ERROR
          when 400..499 then Reason::BAD_REQUEST
          else Reason::ERROR
          end
        end

        def self.rate_limited_error(message, retry_after: nil, limit: nil)
          details = { type: RATE_LIMITED_ERROR_TYPE }
          details[:retry_after_seconds] = retry_after.to_i if retry_after.present?
          details[:limit] = limit.to_s if limit.present?
          details[:message] = message.to_s

          error(rate_limited_text(retry_after, limit), details, reason: Reason::ERROR)
        end

        def self.error?(result)
          result.is_a?(Hash) && !!result[:isError]
        end

        def self.error_message(result)
          content = result[:content]
          return unless content.is_a?(Array)

          content.filter_map { |c| c[:text] }.join(', ').presence
        end

        def self.rate_limited_text(retry_after, limit)
          subject = limit.present? ? format(_('Rate limited by %{limit}.'), limit: limit) : _('Rate limited.')
          return subject if retry_after.blank?

          delay = n_('Retry after %d second.', 'Retry after %d seconds.', retry_after.to_i) % retry_after.to_i
          "#{subject} #{delay}"
        end
        private_class_method :rate_limited_text

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
end
