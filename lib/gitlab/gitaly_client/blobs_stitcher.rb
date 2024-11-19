# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class BlobsStitcher
      include Enumerable

      def initialize(rpc_response, filter_function: nil)
        @rpc_response = rpc_response
        @filter_function = filter_function
      end

      def each
        current_blob_data = nil

        @rpc_response.each do |msg|
          if msg.oid.blank? && msg.data.blank?
            next
          # rubocop: disable Lint/DuplicateBranch -- No duplication, filter can be supplied
          elsif removed_by_filter(msg)
            # rubocop: enable Lint/DuplicateBranch
            next
          elsif msg.oid.present?
            yield new_blob(current_blob_data) if current_blob_data

            current_blob_data = msg.to_h.slice(:oid, :path, :size, :revision, :mode)
            current_blob_data[:data_parts] = [msg.data]
          else
            current_blob_data[:data_parts] << msg.data
          end
        end

        yield new_blob(current_blob_data) if current_blob_data
      end

      private

      def removed_by_filter(msg)
        return unless @filter_function

        !@filter_function.call(msg)
      end

      def new_blob(blob_data)
        data = blob_data[:data_parts].join

        Gitlab::Git::Blob.new(
          id: blob_data[:oid],
          mode: blob_data[:mode]&.to_s(8),
          name: blob_data[:path] && File.basename(blob_data[:path]),
          path: blob_data[:path],
          size: blob_data[:size],
          commit_id: blob_data[:revision],
          data: data
        )
      end
    end
  end
end
