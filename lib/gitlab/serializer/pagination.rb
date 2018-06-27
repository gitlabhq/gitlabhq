module Gitlab
  module Serializer
    class Pagination
      InvalidResourceError = Class.new(StandardError)
      include ::API::Helpers::Pagination

      def initialize(request, response)
        @request = request
        @response = response
      end

      def paginate(resource)
        if resource.respond_to?(:page)
          super(resource)
        else
          raise InvalidResourceError
        end
      end

      # Methods needed by `API::Helpers::Pagination`
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
