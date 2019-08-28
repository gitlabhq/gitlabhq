# frozen_string_literal: true

module Gitlab
  module InternalPostReceive
    class Response
      attr_accessor :reference_counter_decreased
      attr_reader :messages

      Message = Struct.new(:message, :type) do
        def self.basic(text)
          new(text, :basic)
        end

        def self.alert(text)
          new(text, :alert)
        end
      end

      def initialize
        @messages = []
        @reference_counter_decreased = false
      end

      def add_merge_request_urls(urls_data)
        urls_data.each do |url_data|
          add_merge_request_url(url_data)
        end
      end

      def add_merge_request_url(url_data)
        message = if url_data[:new_merge_request]
                    "To create a merge request for #{url_data[:branch_name]}, visit:"
                  else
                    "View merge request for #{url_data[:branch_name]}:"
                  end

        message += "\n  #{url_data[:url]}"

        add_basic_message(message)
      end

      def add_basic_message(text)
        @messages << Message.basic(text) if text.present?
      end

      def add_alert_message(text)
        @messages.unshift(Message.alert(text)) if text.present?
      end
    end
  end
end
