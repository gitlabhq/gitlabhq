module Gitlab
  module Geo
    class TransferRequest < BaseRequest
      def headers
        super.merge({ 'X-Sendfile-Type' => 'X-Sendfile' })
      end
    end
  end
end
