# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module Processor
      module SanitizerProcessor
        SANITIZED_HTTP_HEADERS = %w[Authorization Private-Token Job-Token].freeze
        SANITIZED_ATTRIBUTES = %i[user contexts extra tags].freeze

        # This processor removes sensitive fields or headers from the event
        # before sending. Sentry versions above 4.0 don't support
        # sanitized_fields and sanitized_http_headers anymore. The official
        # document recommends using before_send instead.
        #
        # For more information, please visit:
        # https://docs.sentry.io/platforms/ruby/guides/rails/configuration/filtering/#using-beforesend
        def self.call(event)
          if event.request.present?
            event.request.cookies = {}
            event.request.data = {}
          end

          if event.request.present? && event.request.headers.is_a?(Hash)
            header_filter = ActiveSupport::ParameterFilter.new(SANITIZED_HTTP_HEADERS)
            event.request.headers = header_filter.filter(event.request.headers)
          end

          attribute_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
          SANITIZED_ATTRIBUTES.each do |attribute|
            event.send("#{attribute}=", attribute_filter.filter(event.send(attribute))) # rubocop:disable GitlabSecurity/PublicSend
          end

          if event.request.present? && event.request.query_string.present?
            query = Rack::Utils.parse_nested_query(event.request.query_string)
            query = attribute_filter.filter(query)
            query = Rack::Utils.build_nested_query(query)
            event.request.query_string = query
          end

          event
        end
      end
    end
  end
end
