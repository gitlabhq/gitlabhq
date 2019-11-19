# frozen_string_literal: true

module Gitlab
  module Serializer
    class Pagination
      InvalidResourceError = Class.new(StandardError)

      def initialize(request, response)
        @request = request
        @response = response
      end

      def paginate(resource)
        if resource.respond_to?(:page)
          ::Gitlab::Pagination::OffsetPagination.new(self).paginate(resource)
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
