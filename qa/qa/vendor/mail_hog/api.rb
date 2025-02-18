# frozen_string_literal: true

module QA
  module Vendor
    module MailHog
      # Represents a Set of messages from a MailHog response
      class Messages
        include Enumerable

        attr_reader :data

        def initialize(data)
          @data = data
        end

        def total
          data['total']
        end

        def each
          data['items']&.each do |item|
            yield MessageItem.new(item)
          end
        end
      end

      # Represents an email item from a MailHog response
      class MessageItem
        attr_reader :data

        def initialize(data)
          @data = data
        end

        def to
          data.dig('Content', 'Headers', 'To', 0)
        end

        def subject
          data.dig('Content', 'Headers', 'Subject', 0)
        end

        def body
          data.dig('Content', 'Body')
        end
      end

      class API
        include Support::API

        attr_reader :hostname

        def initialize(hostname: QA::Runtime::Env.mailhog_hostname || 'localhost')
          @hostname = hostname
        end

        def base_url
          "http://#{hostname}:8025"
        end

        def api_messages_url(version: 2)
          "#{base_url}/api/v#{version}/messages"
        end

        def delete_messages
          delete(api_messages_url(version: 1))
        end

        def fetch_messages
          Messages.new(JSON.parse(fetch_messages_json))
        end

        def fetch_messages_json
          get(api_messages_url).body
        end
      end
    end
  end
end
