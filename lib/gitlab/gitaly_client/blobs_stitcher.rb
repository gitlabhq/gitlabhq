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

            current_blob_data = blob_attributes(msg)
            current_blob_data[:data_parts] = [msg.data]
          else
            current_blob_data[:data_parts] << msg.data
          end
        end

        yield new_blob(current_blob_data) if current_blob_data
      end

      private

      # Avoid using #to_h because google-protobuf v4 omits default values
      def blob_attributes(msg)
        # msg can be a Gitaly::ListAllBlobsResponse::Blob or Gitaly::GetBlobsResponse
        %i[oid path size revision mode].each_with_object({}) do |name, attrs|
          attrs[name] = msg.send(name) if msg.respond_to?(name) # rubocop:disable GitlabSecurity/PublicSend -- This is safe because these fields are in the protobuf
        end
      end

      def removed_by_filter(msg)
        return unless @filter_function

        !@filter_function.call(msg)
      end

      def new_blob(blob_data)
        data = blob_data[:data_parts].join

        Gitlab::Git::Blob.new(
          id: blob_data[:oid],
          mode: blob_data[:mode]&.to_i&.to_s(8),
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
