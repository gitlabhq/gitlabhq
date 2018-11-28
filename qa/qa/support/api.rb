module QA
  module Support
    module Api
      def post(url, payload)
        RestClient::Request.execute(
          method: :post,
          url: url,
          payload: payload,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end

      def get(url)
        RestClient::Request.execute(
          method: :get,
          url: url,
          verify_ssl: false)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end

      def parse_body(response)
        JSON.parse(response.body, symbolize_names: true)
      end
    end
  end
end
