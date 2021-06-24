# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class ListBlobsAdapter
      include Enumerable

      def initialize(rpc_response)
        @rpc_response = rpc_response
      end

      def each
        @rpc_response.each do |msg|
          msg.blobs.each do |blob|
            yield blob
          end
        end
      end
    end
  end
end
