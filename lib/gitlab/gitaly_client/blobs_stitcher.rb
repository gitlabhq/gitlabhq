module Gitlab
  module GitalyClient
    class BlobsStitcher
      include Enumerable

      def initialize(rpc_response)
        @rpc_response = rpc_response
      end

      def each
        current_blob_data = nil

        @rpc_response.each do |msg|
          begin
            if msg.oid.blank? && msg.data.blank?
              next
            elsif msg.oid.present?
              yield new_blob(current_blob_data) if current_blob_data

              current_blob_data = msg.to_h.slice(:oid, :path, :size, :revision, :mode)
              current_blob_data[:data] = msg.data.dup
            else
              current_blob_data[:data] << msg.data
            end
          end
        end

        yield new_blob(current_blob_data) if current_blob_data
      end

      private

      def new_blob(blob_data)
        Gitlab::Git::Blob.new(
          id: blob_data[:oid],
          mode: blob_data[:mode].to_s(8),
          name: File.basename(blob_data[:path]),
          path: blob_data[:path],
          size: blob_data[:size],
          commit_id: blob_data[:revision],
          data: blob_data[:data],
          binary: Gitlab::Git::Blob.binary?(blob_data[:data])
        )
      end
    end
  end
end
