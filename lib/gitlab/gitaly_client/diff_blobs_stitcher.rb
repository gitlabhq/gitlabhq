# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class DiffBlobsStitcher
      include Enumerable

      def initialize(rpc_response)
        @rpc_response = rpc_response
      end

      def each
        current_diff_blob = nil

        @rpc_response.each do |diff_blob_msg|
          if current_diff_blob.nil?
            diff_blobs_params = diff_blob_msg.to_h.slice(
              *Gitlab::GitalyClient::DiffBlob::ATTRS
            )

            current_diff_blob = Gitlab::GitalyClient::DiffBlob.new(diff_blobs_params)
          else
            current_diff_blob.patch = "#{current_diff_blob.patch}#{diff_blob_msg.patch}"
            current_diff_blob.status = diff_blob_msg.status
          end

          if current_diff_blob.status == :STATUS_END_OF_PATCH
            yield current_diff_blob
            current_diff_blob = nil
          end
        end
      end

      private

      attr_reader :rpc_response
    end
  end
end
