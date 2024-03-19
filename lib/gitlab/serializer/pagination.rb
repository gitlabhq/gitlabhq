# frozen_string_literal: true

module Gitlab
  module Serializer
    class Pagination
      InvalidResourceError = Class.new(StandardError)

      class CursorPagination < Gitlab::Pagination::Base
        attr_reader :request_context

        delegate :params, :header, to: :request_context

        def initialize(request_context)
          @request_context = request_context
        end

        def paginate(resource)
          resource
            .tap { |paginator| apply_pagination_headers(paginator) }
            .records
            .tap { |records| header('X-Per-Page', records.count) }
        end

        private

        def apply_pagination_headers(paginator)
          header('X-Next-Page', paginator.cursor_for_next_page)
          header('X-Page', params[:cursor])
          header('X-Page-Type', 'cursor')
          header('X-Prev-Page', paginator.cursor_for_previous_page)
          Gitlab::Pagination::Keyset::HeaderBuilder
            .new(request_context)
            .add_next_page_header(cursor: paginator.cursor_for_next_page)
        end
      end

      def initialize(request, response)
        @request = request
        @response = response
      end

      def paginate(resource)
        if resource.respond_to?(:page)
          ::Gitlab::Pagination::OffsetPagination.new(self).paginate(resource)
        elsif resource.respond_to?(:cursor_for_next_page)
          CursorPagination.new(self).paginate(resource)
        else
          raise InvalidResourceError
        end
      end

      # Methods needed by `Gitlab::Pagination::OffsetPagination`
      #

      attr_reader :request

      def params
        @request.query_parameters
      end

      def header(header, value)
        @response.headers[header] = value
      end
    end
  end
end
