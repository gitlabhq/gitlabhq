# frozen_string_literal: true

module Gitlab
  module SecretDetection
    module GRPC
      class StreamRequestEnumerator
        def initialize(requests = [])
          @requests = requests
        end

        # yields a request, waiting between 0 and 1 seconds between requests
        #
        # @return an Enumerable that yields a request input
        def each_item
          return enum_for(:each_item) unless block_given?

          @requests.each do |request|
            yield request
          end
        end
      end
    end
  end
end
